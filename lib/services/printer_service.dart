import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PrinterService extends ChangeNotifier {
  final ThermalPrinterFlutter _printer = ThermalPrinterFlutter();
  Printer? _activePrinter;
  bool _isConnecting = false;
  String? _bridgeToken;

  Printer? get activePrinter => _activePrinter;
  bool get isConnecting => _isConnecting;

  static const String _prefPrinterTypeKey = 'last_printer_type';
  static const String _prefPrinterNameKey = 'last_printer_name';
  static const String _prefPrinterIpKey = 'last_printer_ip';
  static const String _prefBridgeTokenKey = 'last_bridge_token';

  PrinterService() {
    _initAutoConnect();
  }

  Future<void> _initAutoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTypeStr = prefs.getString(_prefPrinterTypeKey);
    final lastName = prefs.getString(_prefPrinterNameKey);
    final lastIp = prefs.getString(_prefPrinterIpKey);
    _bridgeToken = prefs.getString(_prefBridgeTokenKey);

    if (lastTypeStr != null && lastName != null) {
      if (lastTypeStr == 'network' && lastIp != null) {
        _activePrinter = Printer(
          type: PrinterType.network,
          name: lastName,
          ip: lastIp,
          port: '9100',
        );
        notifyListeners();
        return;
      }

      PrinterType type = lastTypeStr == 'usb'
          ? PrinterType.usb
          : PrinterType.bluetooth;
      try {
        final printers = await _printer.getPrinters(printerType: type);
        final matchingPrinter = printers
            .where((p) => p.name == lastName)
            .firstOrNull;
        if (matchingPrinter != null) {
          _activePrinter = matchingPrinter;
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Auto-connect failed: $e");
      }
    }
  }

  Future<void> _savePrinter(Printer printer, {String? ip}) async {
    final prefs = await SharedPreferences.getInstance();

    String typeStr;
    if (printer.type == PrinterType.usb) {
      typeStr = 'usb';
    } else if (printer.type == PrinterType.bluetooth) {
      typeStr = 'bluetooth';
    } else {
      typeStr = 'network';
    }

    await prefs.setString(_prefPrinterTypeKey, typeStr);
    await prefs.setString(_prefPrinterNameKey, printer.name);

    if (ip != null) {
      await prefs.setString(_prefPrinterIpKey, ip);
    }

    if (_bridgeToken != null) {
      await prefs.setString(_prefBridgeTokenKey, _bridgeToken!);
    }
  }

  Future<void> _clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPrinterTypeKey);
    await prefs.remove(_prefPrinterNameKey);
    await prefs.remove(_prefPrinterIpKey);
  }

  Future<bool> selectUsbPrinter() async {
    _isConnecting = true;
    notifyListeners();

    try {
      if (await _printer.isWebUsbSupported()) {
        final target = await _printer.requestPrinter(
          printerType: PrinterType.usb,
        );
        if (target != null) {
          _activePrinter = target;
          await _savePrinter(target);
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error selecting USB printer: $e");
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> selectBluetoothPrinter() async {
    _isConnecting = true;
    notifyListeners();

    try {
      if (await _printer.isWebBluetoothSupported()) {
        final target = await _printer.requestPrinter(
          printerType: PrinterType.bluetooth,
        );
        if (target != null) {
          _activePrinter = target;
          await _savePrinter(target);
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error selecting Bluetooth printer: $e");
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> selectNetworkPrinter(String ip, String token) async {
    _isConnecting = true;
    notifyListeners();

    try {
      _bridgeToken = token;
      _activePrinter = Printer(
        type: PrinterType.network,
        name: 'Network ($ip)',
        ip: ip,
        port: '9100',
      );
      await _savePrinter(_activePrinter!, ip: ip);
      return true;
    } catch (e) {
      debugPrint("Error selecting Network printer: $e");
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (_activePrinter != null) {
      try {
        if (_activePrinter!.type != PrinterType.network) {
          await _printer.disconnect(printer: _activePrinter!);
        }
      } catch (e) {
        // Ignored
      }
      _activePrinter = null;
      await _clearSavedPrinter();
      notifyListeners();
    }
  }

  Future<bool> printText(String text) async {
    if (_activePrinter == null) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      final bytes = <int>[
        ...generator.text(text),
        ...generator.feed(2),
        // ...generator.cut(),
      ];

      if (_activePrinter!.type == PrinterType.network) {
        return await _printViaBridge(bytes, _activePrinter!.ip!);
      } else {
        await _printer.printBytes(bytes: bytes, printer: _activePrinter!);
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
      if (_bridgeToken != null && _bridgeToken!.isNotEmpty) {
        wsUrl += '/?token=$_bridgeToken';
      }

      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      final payload = jsonEncode({"target": targetIp, "bytes": bytes});

      channel.sink.add(payload);

      // Wait for success response or timeout
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
