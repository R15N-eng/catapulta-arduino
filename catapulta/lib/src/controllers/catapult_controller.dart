import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';

class CatapultController {
  final BluetoothService _bluetoothService;

  CatapultController(this._bluetoothService);

  bool get isConnected => _bluetoothService.isConnected;

  Future<List<BluetoothDevice>> getPairedDevices() =>
      _bluetoothService.getPairedDevices();

  Future<void> connect(BluetoothDevice device) =>
      _bluetoothService.connect(device);

  Future<void> disconnect() => _bluetoothService.disconnect();

  Future<bool> isBluetoothEnabled() =>
      _bluetoothService.isBluetoothEnabled();

  Future<void> requestBluetoothEnable() =>
      _bluetoothService.requestBluetoothEnable();

  // Converte cm (50–400) para percentual (0–100) que o Arduino espera
  Future<void> carregar(int distanciaCm) async {
    final percent = ((distanciaCm - 50) * 100 ~/ 350).clamp(0, 100);
    await _bluetoothService.sendValue(percent);
    await Future.delayed(const Duration(milliseconds: 300));
    await _bluetoothService.sendValue(101);
  }

  Future<void> lancar() async {
    await _bluetoothService.sendValue(102);
  }

  Future<void> travar() async {
    await _bluetoothService.sendValue(103);
  }


  Future<void> entrarModoCalibracao() async {
    await _bluetoothService.sendValue(503);
  }

  Future<void> entrarModoNormal() async {
    await _bluetoothService.sendValue(504);
  }

  // testar() fica assim, sem o 500 no final:
  Future<void> testar(int passos) async {
    await _bluetoothService.sendValue(passos);
    await Future.delayed(const Duration(milliseconds: 300));
  }

}