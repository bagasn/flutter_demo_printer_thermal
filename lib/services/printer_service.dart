import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PrinterService extends ChangeNotifier {
  final ThermalPrinterFlutter _printer = ThermalPrinterFlutter();
  
  // Map of active printers by role (e.g. 'kasir', 'dapur')
  final Map<String, Printer> _activePrinters = {};
  
  // Track connection status per role to show loading spinner
  final Map<String, bool> _connectingState = {};

  Printer? get receiptPrinter => _activePrinters['kasir'];
  Printer? get kitchenPrinter => _activePrinters['dapur'];

  bool isConnecting(String role) => _connectingState[role] ?? false;
  
  // Shared token for network bridge
  String? _bridgeToken;

  static const List<String> _roles = ['kasir', 'dapur'];

  PrinterService() {
    _initAutoConnect();
  }

  void _setConnecting(String role, bool status) {
    _connectingState[role] = status;
    notifyListeners();
  }

  Future<void> _initAutoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    _bridgeToken = prefs.getString('last_bridge_token');

    for (var role in _roles) {
      final lastTypeStr = prefs.getString('last_printer_type_$role');
      final lastName = prefs.getString('last_printer_name_$role');
      final lastIp = prefs.getString('last_printer_ip_$role');

      if (lastTypeStr != null && lastName != null) {
        if (lastTypeStr == 'network' && lastIp != null) {
          _activePrinters[role] = Printer(
            type: PrinterType.network,
            name: lastName,
            ip: lastIp,
            port: '9100',
          );
          notifyListeners();
          continue;
        }

        PrinterType type = lastTypeStr == 'usb' ? PrinterType.usb : PrinterType.bluetooth;
        try {
          final printers = await _printer.getPrinters(printerType: type);
          final matchingPrinter = printers.where((p) => p.name == lastName).firstOrNull;
          if (matchingPrinter != null) {
            _activePrinters[role] = matchingPrinter;
            notifyListeners();
          }
        } catch (e) {
          debugPrint("Auto-connect failed for $role: $e");
        }
      }
    }
  }

  Future<void> _savePrinter(String role, Printer printer, {String? ip}) async {
    final prefs = await SharedPreferences.getInstance();
    
    String typeStr;
    if (printer.type == PrinterType.usb) {
      typeStr = 'usb';
    } else if (printer.type == PrinterType.bluetooth) {
      typeStr = 'bluetooth';
    } else {
      typeStr = 'network';
    }

    await prefs.setString('last_printer_type_$role', typeStr);
    await prefs.setString('last_printer_name_$role', printer.name);
    
    if (ip != null) {
      await prefs.setString('last_printer_ip_$role', ip);
    }
    
    if (_bridgeToken != null) {
      await prefs.setString('last_bridge_token', _bridgeToken!);
    }
  }

  Future<void> _clearSavedPrinter(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_printer_type_$role');
    await prefs.remove('last_printer_name_$role');
    await prefs.remove('last_printer_ip_$role');
  }

  Future<bool> selectUsbPrinter(String role) async {
    _setConnecting(role, true);

    try {
      if (await _printer.isWebUsbSupported()) {
        final target = await _printer.requestPrinter(printerType: PrinterType.usb);
        if (target != null) {
          _activePrinters[role] = target;
          await _savePrinter(role, target);
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error selecting USB printer: $e");
    } finally {
      _setConnecting(role, false);
    }
    return false;
  }

  Future<bool> selectBluetoothPrinter(String role) async {
    _setConnecting(role, true);

    try {
      if (await _printer.isWebBluetoothSupported()) {
        final target = await _printer.requestPrinter(printerType: PrinterType.bluetooth);
        if (target != null) {
          _activePrinters[role] = target;
          await _savePrinter(role, target);
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error selecting Bluetooth printer: $e");
    } finally {
      _setConnecting(role, false);
    }
    return false;
  }

  Future<bool> selectNetworkPrinter(String ip, String token, String role) async {
    _setConnecting(role, true);

    try {
      _bridgeToken = token;
      final newPrinter = Printer(
        type: PrinterType.network,
        name: 'Network ($ip)',
        ip: ip,
        port: '9100',
      );
      _activePrinters[role] = newPrinter;
      await _savePrinter(role, newPrinter, ip: ip);
      return true;
    } catch (e) {
      debugPrint("Error selecting Network printer: $e");
      return false;
    } finally {
      _setConnecting(role, false);
    }
  }

  Future<void> disconnect(String role) async {
    final printerToDisconnect = _activePrinters[role];
    if (printerToDisconnect != null) {
      try {
        if (printerToDisconnect.type != PrinterType.network) {
          await _printer.disconnect(printer: printerToDisconnect);
        }
      } catch (e) {
        // Ignored
      }
      _activePrinters.remove(role);
      await _clearSavedPrinter(role);
      notifyListeners();
    }
  }

  Future<bool> printText(String text, {required String role}) async {
    final targetPrinter = _activePrinters[role];
    if (targetPrinter == null) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      final bytes = <int>[
        ...generator.text(text),
        ...generator.feed(2),
        // ...generator.cut(),
      ];

      if (targetPrinter.type == PrinterType.network) {
        return await _printViaBridge(bytes, targetPrinter.ip);
      } else {
        await _printer.printBytes(bytes: bytes, printer: targetPrinter);
        return true;
      }
    } catch (e) {
      debugPrint("Print error: $e");
      return false;
    }
  }

  Future<bool> _printViaBridge(List<int> bytes, String targetIp) async {
    try {
      String wsUrl = 'ws://localhost:8921';
      final token = _bridgeToken;
      if (token != null && token.isNotEmpty) {
        wsUrl += '/?token=$token';
      }
      
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      final payload = jsonEncode({
        "target": targetIp,
        "bytes": bytes,
      });

      channel.sink.add(payload);
      
      bool success = false;
      await for (final message in channel.stream) {
        final data = jsonDecode(message);
        if (data['status'] == 'success') {
          success = true;
          break;
        } else {
          debugPrint("Bridge error: ${data['message']}");
          break;
        }
      }
      
      await channel.sink.close();
      return success;
    } catch (e) {
      debugPrint("WebSocket Bridge error: $e");
      return false;
    }
  }
}
