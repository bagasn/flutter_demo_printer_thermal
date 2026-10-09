import 'package:flutter/material.dart';

import '../services/printer_service.dart';

class PrinterSelectionPage extends StatelessWidget {
  final PrinterService printerService;

  const PrinterSelectionPage({super.key, required this.printerService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: printerService,
      builder: (context, child) {
        final activePrinter = printerService.activePrinter;

        return Scaffold(
          appBar: AppBar(title: const Text('Pilih Printer')),
          body: Center(
            child: printerService.isConnecting
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (activePrinter != null) ...[
                        const Icon(Icons.print, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'Printer Aktif: ${activePrinter.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Tipe: ${activePrinter.type.name}'),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => printerService.disconnect(),
                          icon: const Icon(Icons.link_off),
                          label: const Text('Putuskan Printer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade900,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.print_disabled,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada printer yang terhubung',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => printerService.selectUsbPrinter(),
                          icon: const Icon(Icons.usb),
                          label: const Text('Pilih Printer USB'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              printerService.selectBluetoothPrinter(),
                          icon: const Icon(Icons.bluetooth),
                          label: const Text('Pilih Printer Bluetooth'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showNetworkPrinterDialog(context),
                          icon: const Icon(Icons.wifi),
                          label: const Text(
                            'Pilih Printer Jaringan (via Bridge)',
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _showNetworkPrinterDialog(BuildContext context) async {
    final ipController = TextEditingController(text: '192.168.1.100');
    final tokenController = TextEditingController(text: 'rahasia123');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Printer Jaringan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address Printer',
                  hintText: '192.168.1.x',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Auth Token Bridge (opsional)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pastikan aplikasi "printer_extension" berjalan di komputer ini.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                printerService.selectNetworkPrinter(
                  ipController.text.trim(),
                  tokenController.text.trim(),
                );
              },
              child: const Text('Hubungkan'),
            ),
          ],
        );
      },
    );
  }
}
