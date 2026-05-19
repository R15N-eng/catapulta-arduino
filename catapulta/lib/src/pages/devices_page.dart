import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../controllers/catapult_controller.dart';

class DevicesPage extends StatefulWidget {
  final CatapultController controller;

  const DevicesPage({super.key, required this.controller});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true;
  String? _connectingAddress;

  static const neonBlue = Color(0xFF00BFFF);
  static const neonPurple = Color(0xFF1A5F8A);

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final devices = await widget.controller.getPairedDevices();
    setState(() {
      _devices = devices.cast<BluetoothDevice>();
      _loading = false;
    });
  }

  Future<void> _connectTo(BluetoothDevice device) async {
    setState(() => _connectingAddress = device.address);
    try {
      await widget.controller.connect(device);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _connectingAddress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF050508),
        title: const Text(
          'DISPOSITIVOS PAREADOS',
          style: TextStyle(
            color: neonBlue,
            fontSize: 14,
            letterSpacing: 3,
          ),
        ),
        iconTheme: const IconThemeData(color: neonBlue),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: neonBlue),
            )
          : _devices.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum dispositivo pareado\nencontrado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: neonBlue.withOpacity(0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isConnecting =
                        _connectingAddress == device.address;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: neonBlue.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF0D1117),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: device.name?.contains('HC-05') == true
                              ? neonPurple
                              : neonBlue.withOpacity(0.5),
                        ),
                        title: Text(
                          device.name ?? 'Desconhecido',
                          style: const TextStyle(
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        subtitle: Text(
                          device.address,
                          style: TextStyle(
                            color: neonBlue.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                        trailing: isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: neonBlue,
                                ),
                              )
                            : Icon(
                                Icons.arrow_forward_ios,
                                color: neonBlue.withOpacity(0.5),
                                size: 14,
                              ),
                        onTap: isConnecting
                            ? null
                            : () => _connectTo(device),
                      ),
                    );
                  },
                ),
    );
  }
}