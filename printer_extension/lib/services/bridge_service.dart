import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

class BridgeService extends ChangeNotifier {
  // Server state
  HttpServer? _server;
  bool get isRunning => _server != null;

  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  // Configuration
  final int port = 8921;
  bool enableAuth = true;
  String authToken = 'rahasia123';
  String testIp = '192.168.1.100';

  void addLog(String message) {
    _logs.insert(
      0,
      '${DateTime.now().toIso8601String().split('T').last.split('.').first} - $message',
    );
    if (_logs.length > 50) _logs.removeLast();
    notifyListeners();
  }

  void updateEnableAuth(bool value) {
    if (isRunning) return;
    enableAuth = value;
    notifyListeners();
  }

  void updateAuthToken(String token) {
    authToken = token;
    notifyListeners();
  }

  void updateTestIp(String ip) {
    testIp = ip;
    notifyListeners();
  }

  bool _validateAuth(Request request) {
    if (!enableAuth) return true;
    final token = request.url.queryParameters['token'];
    return token == authToken;
  }

  Future<void> startServer() async {
    if (isRunning) return;

    final wsHandler = webSocketHandler((webSocket, protocol) {
      addLog('Klien terhubung (Protocol: $protocol).');

      webSocket.stream.listen(
        (message) async {
          try {
            final data = jsonDecode(message);
            final targetIp = data['target'] as String;
            final bytes = (data['bytes'] as List).cast<int>();

            addLog('Menerima perintah cetak. Meneruskan ke $targetIp...');

            final socket = await Socket.connect(
              targetIp,
              9100,
              timeout: const Duration(seconds: 5),
            );
            socket.add(bytes);
            await socket.flush();
            await socket.close();

            addLog('Berhasil mencetak ke $targetIp');

            webSocket.sink.add(jsonEncode({"status": "success"}));
          } catch (e) {
            addLog('Error: $e');
            webSocket.sink.add(
              jsonEncode({"status": "error", "message": e.toString()}),
            );
          }
        },
        onDone: () {
          addLog('Klien terputus.');
        },
      );
    });

    FutureOr<Response> handler(Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type',
          },
        );
      }

      if (!_validateAuth(request)) {
        addLog('Koneksi ditolak: Token tidak valid.');
        return Response.forbidden('Invalid auth token');
      }

      return wsHandler(request);
    }

    try {
      _server = await io.serve(handler, InternetAddress.anyIPv4, port);
      addLog('Server berjalan di port $port');
      notifyListeners();
    } catch (e) {
      addLog('Gagal menjalankan server: $e');
    }
  }

  Future<void> stopServer() async {
    if (!isRunning) return;
    await _server?.close(force: true);
    _server = null;
    addLog('Server dihentikan.');
    notifyListeners();
  }

  Future<void> testPrint() async {
    final ip = testIp.trim();
    if (ip.isEmpty) return;

    addLog('Mencoba test print ke $ip:9100...');
    try {
      final socket = await Socket.connect(
        ip,
        9100,
        timeout: const Duration(seconds: 5),
      );

      final init = [27, 64];
      final textBytes = utf8.encode('TEST CONNECTION SUCCESS!\n\n\n\n');
      final cut = [29, 86, 0];

      socket.add([...init, ...textBytes, ...cut]);
      await socket.flush();
      await socket.close();

      addLog('Test print berhasil! Koneksi TCP lancar.');
    } catch (e) {
      addLog('Test print gagal: $e');
    }
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }
}
