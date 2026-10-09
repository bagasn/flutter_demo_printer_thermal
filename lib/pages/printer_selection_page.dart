import 'package:flutter/material.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import '../services/printer_service.dart';

class PrinterSelectionPage extends StatelessWidget {
  final PrinterService printerService;

  const PrinterSelectionPage({super.key, required this.printerService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Printer')),
      body: ListenableBuilder(
        listenable: printerService,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildPrinterCard(
                  context: context,
                  title: 'Printer Kasir (Receipt)',
                  role: 'kasir',
                  activePrinter: printerService.receiptPrinter,
                ),
                const SizedBox(height: 24),
                _buildPrinterCard(
                  context: context,
                  title: 'Printer Dapur (Kitchen)',
                  role: 'dapur',
                  activePrinter: printerService.kitchenPrinter,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrinterCard({
    required BuildContext context,
    required String title,
    required String role,
    required Printer? activePrinter,
  }) {
    final isConnecting = printerService.isConnecting(role);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isConnecting
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (activePrinter != null) ...[
                    const Icon(Icons.print, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Aktif: ${activePrinter.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Tipe: ${activePrinter.type.name}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => printerService.disconnect(role),
                      icon: const Icon(Icons.link_off),
                      label: const Text('Putuskan Printer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade900,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.print_disabled, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum terhubung',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => printerService.selectUsbPrinter(role),
                      icon: const Icon(Icons.usb),
                      label: const Text('Pilih USB'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => printerService.selectBluetoothPrinter(role),
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('Pilih Bluetooth'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showNetworkPrinterDialog(context, role),
                      icon: const Icon(Icons.wifi),
                      label: const Text('Pilih Network'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _showNetworkPrinterDialog(BuildContext context, String role) async {
    final ipController = TextEditingController(text: '192.168.1.100');
    final tokenController = TextEditingController(text: 'rahasia123');
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Printer Jaringan ($role)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(labelText: 'IP Address Printer', hintText: '192.168.1.x'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: 'Auth Token Bridge (opsional)'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pastikan aplikasi "printer_extension" berjalan di komputer ini.', 
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                printerService.selectNetworkPrinter(
                  ipController.text.trim(), 
                  tokenController.text.trim(),
                  role,
                );
              },
              child: const Text('Hubungkan'),
            ),
          ],
        );
      }
    );
  }
}
