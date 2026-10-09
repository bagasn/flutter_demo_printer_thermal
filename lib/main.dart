import 'package:flutter/material.dart';
import 'services/printer_service.dart';
import 'pages/printer_selection_page.dart';
import 'pages/test_print_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Printer Web',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainHomePage(),
    );
  }
}

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  final PrinterService _printerService = PrinterService();
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PrinterSelectionPage(printerService: _printerService),
      TestPrintPage(printerService: _printerService),
    ];
  }

  @override
  void dispose() {
    _printerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_bluetooth),
            label: 'Pilih Printer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.print),
            label: 'Test Print',
          ),
        ],
      ),
    );
  }
}
