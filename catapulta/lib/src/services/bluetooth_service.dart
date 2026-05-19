import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  BluetoothConnection? _connection;

  bool get isConnected =>
      _connection != null && (_connection!.isConnected);

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    _connection = await BluetoothConnection.toAddress(device.address);
  }

  Future<void> sendValue(int value) async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('Bluetooth não conectado');
    }
    _connection!.output.add(utf8.encode('$value\n'));
    await _connection!.output.allSent;
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  Future<bool> isBluetoothEnabled() async {
    return await FlutterBluetoothSerial.instance.isEnabled ?? false;
  }

  Future<void> requestBluetoothEnable() async {
    await FlutterBluetoothSerial.instance.requestEnable();
  }
}