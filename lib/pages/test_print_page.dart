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
  bool _isPrinting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handlePrint() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan teks terlebih dahulu')),
      );
      return;
    }

    if (widget.printerService.activePrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih printer terlebih dahulu di halaman sebelah')),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    final success = await widget.printerService.printText(text);
    
    if (mounted) {
      setState(() {
        _isPrinting = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mengirim perintah cetak!')),
        );
        _textController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mencetak. Periksa koneksi printer Anda.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Print'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: widget.printerService,
              builder: (context, child) {
                final hasPrinter = widget.printerService.activePrinter != null;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasPrinter ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasPrinter ? Colors.green.shade200 : Colors.red.shade200,
                    )
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasPrinter ? Icons.check_circle : Icons.warning,
                        color: hasPrinter ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasPrinter 
                              ? 'Printer siap: ${widget.printerService.activePrinter!.name}'
                              : 'Printer belum dipilih',
                          style: TextStyle(
                            color: hasPrinter ? Colors.green.shade900 : Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            ElevatedButton(
              onPressed: _isPrinting ? null : _handlePrint,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isPrinting 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Text('Print Sekarang', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
