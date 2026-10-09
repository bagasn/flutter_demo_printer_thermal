import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'services/bridge_service.dart';

void main() {
  runApp(const PrinterExtensionApp());
}

class PrinterExtensionApp extends StatefulWidget {
  const PrinterExtensionApp({super.key});

  @override
  State<PrinterExtensionApp> createState() => _PrinterExtensionAppState();
}

class _PrinterExtensionAppState extends State<PrinterExtensionApp> {
  final BridgeService _bridgeService = BridgeService();

  @override
  void dispose() {
    _bridgeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Printer Bridge Extension',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: BridgeHomePage(bridgeService: _bridgeService),
    );
  }
}
