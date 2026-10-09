import 'package:flutter/material.dart';
import '../services/printer_service.dart';

class TestPrintPage extends StatefulWidget {
  final PrinterService printerService;

  const TestPrintPage({super.key, required this.printerService});

  @override
  State<TestPrintPage> createState() => _TestPrintPageState();
}

class _TestPrintPageState extends State<TestPrintPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isPrintingKasir = false;
  bool _isPrintingDapur = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handlePrint(String role) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan teks terlebih dahulu')),
      );
      return;
    }

    if (role == 'kasir' && widget.printerService.receiptPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer Kasir belum dipilih')),
      );
      return;
    }
    
    if (role == 'dapur' && widget.printerService.kitchenPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer Dapur belum dipilih')),
      );
      return;
    }

    setState(() {
      if (role == 'kasir') {
        _isPrintingKasir = true;
      } else {
        _isPrintingDapur = true;
      }
    });

    final success = await widget.printerService.printText(text, role: role);
    
    if (mounted) {
      setState(() {
        if (role == 'kasir') {
          _isPrintingKasir = false;
        } else {
          _isPrintingDapur = false;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil mengirim cetak ke $role!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak ke $role. Periksa koneksi.')),
        );
      }
    }
  }

  Widget _buildStatusIndicator(String title, bool isReady, String? printerName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReady ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReady ? Colors.green.shade200 : Colors.red.shade200,
        )
      ),
      child: Row(
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.warning,
            color: isReady ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isReady ? Colors.green.shade900 : Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isReady ? 'Siap: $printerName' : 'Belum dihubungkan',
                  style: TextStyle(
                    color: isReady ? Colors.green.shade900 : Colors.red.shade900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Print'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: widget.printerService,
              builder: (context, child) {
                final kasirPrinter = widget.printerService.receiptPrinter;
                final dapurPrinter = widget.printerService.kitchenPrinter;
                
                return Column(
                  children: [
                    _buildStatusIndicator('Printer Kasir', kasirPrinter != null, kasirPrinter?.name),
                    const SizedBox(height: 12),
                    _buildStatusIndicator('Printer Dapur', dapurPrinter != null, dapurPrinter?.name),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Teks untuk dicetak',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Halo Dunia!',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPrintingKasir ? null : () => _handlePrint('kasir'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isPrintingKasir 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Print Kasir'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPrintingDapur ? null : () => _handlePrint('dapur'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                    ),
                    child: _isPrintingDapur 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Print Dapur'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
