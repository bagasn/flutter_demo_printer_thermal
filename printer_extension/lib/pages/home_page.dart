import 'package:flutter/material.dart';

import '../services/bridge_service.dart';

class BridgeHomePage extends StatefulWidget {
  final BridgeService bridgeService;

  const BridgeHomePage({super.key, required this.bridgeService});

  @override
  State<BridgeHomePage> createState() => _BridgeHomePageState();
}

class _BridgeHomePageState extends State<BridgeHomePage> {
  late final TextEditingController _tokenController;
  late final TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(
      text: widget.bridgeService.authToken,
    );
    _ipController = TextEditingController(text: widget.bridgeService.testIp);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer WebSocket Bridge'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListenableBuilder(
        listenable: widget.bridgeService,
        builder: (context, _) {
          final isRunning = widget.bridgeService.isRunning;
          final logs = widget.bridgeService.logs;

          return Row(
            children: [
              // Sidebar Kiri (Pengaturan)
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.grey.shade50,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Server',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isRunning ? Icons.check_circle : Icons.stop_circle,
                            color: isRunning ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRunning
                                ? 'Berjalan (Port ${widget.bridgeService.port})'
                                : 'Berhenti',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),

                      // Pengaturan Otentikasi
                      const Text(
                        'Pengaturan Otentikasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Gunakan Otentikasi Token'),
                        value: widget.bridgeService.enableAuth,
                        onChanged: isRunning
                            ? null
                            : (val) {
                                widget.bridgeService.updateEnableAuth(val);
                              },
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (widget.bridgeService.enableAuth)
                        TextField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                            labelText: 'Auth Token',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !isRunning,
                          onChanged: (val) =>
                              widget.bridgeService.updateAuthToken(val),
                        ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isRunning
                              ? widget.bridgeService.stopServer
                              : widget.bridgeService.startServer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRunning
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            foregroundColor: isRunning
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                          ),
                          child: Text(
                            isRunning ? 'Stop Server' : 'Start Server',
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),

                      // Uji Coba Printer
                      const Text(
                        'Test Koneksi Jaringan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'IP Printer',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) =>
                            widget.bridgeService.updateTestIp(val),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.bridgeService.testPrint,
                          icon: const Icon(Icons.print),
                          label: const Text('Test Print dari Desktop'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bagian Kanan (Log Monitor)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Server Logs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  logs[index],
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
