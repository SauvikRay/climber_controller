import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart' as fbc;
import 'package:permission_handler/permission_handler.dart';

enum AppConnectionState { disconnected, connecting, connected, error }

class AppBluetoothDevice {
  final String name;
  final String address;
  final int rssi;
  final bool isPaired;

  AppBluetoothDevice({
    required this.name,
    required this.address,
    this.rssi = -70,
    this.isPaired = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBluetoothDevice &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}

abstract class BluetoothService extends ChangeNotifier {
  AppConnectionState get connectionState;
  List<AppBluetoothDevice> get scanResults;
  List<AppBluetoothDevice> get pairedDevices;
  bool get isScanning;
  AppBluetoothDevice? get connectedDevice;
  List<String> get logs;
  bool get isBluetoothOn;

  Future<void> init();
  Future<bool> requestPermissions();
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(AppBluetoothDevice device);
  Future<void> disconnect();
  Future<void> sendData(String data);
  void clearLogs();
}

class PhysicalBluetoothService extends BluetoothService {
  final fbc.FlutterBlueClassic _fbc = fbc.FlutterBlueClassic();
  fbc.BluetoothConnection? _connection;

  AppConnectionState _connectionState = AppConnectionState.disconnected;
  final List<AppBluetoothDevice> _scanResults = [];
  final List<AppBluetoothDevice> _pairedDevices = [];
  bool _isScanning = false;
  AppBluetoothDevice? _connectedDevice;
  final List<String> _logs = [];

  StreamSubscription? _scanSub;
  StreamSubscription? _isScanningSub;
  StreamSubscription? _inputSub;
  StreamSubscription? _adapterStateSub;
  bool _isBluetoothOn = false;

  @override
  AppConnectionState get connectionState => _connectionState;

  @override
  List<AppBluetoothDevice> get scanResults => _scanResults;

  @override
  List<AppBluetoothDevice> get pairedDevices => _pairedDevices;

  @override
  bool get isScanning => _isScanning;

  @override
  AppBluetoothDevice? get connectedDevice => _connectedDevice;

  @override
  List<String> get logs => _logs;

  @override
  bool get isBluetoothOn => _isBluetoothOn;

  @override
  Future<void> init() async {
    // Listen for scan results
    _scanSub = _fbc.scanResults.listen((device) {
      final appDevice = AppBluetoothDevice(
        name: device.name ?? device.alias ?? 'Unknown Device',
        address: device.address,
        rssi: device.rssi ?? -70,
        isPaired: false,
      );
      if (!_scanResults.contains(appDevice)) {
        _scanResults.add(appDevice);
        notifyListeners();
      }
    });

    // Listen for scanning status
    _isScanningSub = _fbc.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    // Listen for adapter state
    _adapterStateSub = _fbc.adapterState.listen((state) {
      _isBluetoothOn = state == fbc.BluetoothAdapterState.on;
      notifyListeners();
    });
    
    final initialState = await _fbc.adapterStateNow;
    _isBluetoothOn = initialState == fbc.BluetoothAdapterState.on;

    // Load bonded devices initially
    await _loadBondedDevices();
  }

  Future<void> _loadBondedDevices() async {
    try {
      final bonded = await _fbc.bondedDevices;
      _pairedDevices.clear();
      if (bonded != null) {
        for (var device in bonded) {
          _pairedDevices.add(
            AppBluetoothDevice(
              name: device.name ?? device.alias ?? 'Unknown Paired Device',
              address: device.address,
              isPaired: true,
            ),
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _addLog("Error loading bonded devices: $e");
    }
  }

  @override
  Future<bool> requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    bool allGranted = true;
    Map<String, PermissionStatus> statusLogs = {};

    for (var permission in permissions) {
      var status = await permission.status;

      if (status.isPermanentlyDenied) {
        allGranted = false;
        statusLogs[permission.toString()] = status;
        break;
      }

      if (!status.isGranted) {
        status = await permission.request();
      }

      statusLogs[permission.toString()] = status;

      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    _addLog("Permissions status: $statusLogs. Granted? $allGranted");
    return allGranted;
  }

  @override
  Future<void> startScan() async {
    _scanResults.clear();
    notifyListeners();
    try {
      _addLog("Starting Bluetooth Scan...");
      _fbc.startScan();
    } catch (e) {
      _addLog("Error starting scan: $e");
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      _addLog("Stopping Bluetooth Scan...");
      _fbc.stopScan();
    } catch (e) {
      _addLog("Error stopping scan: $e");
    }
  }

  @override
  Future<void> connect(AppBluetoothDevice device) async {
    await stopScan();
    _connectionState = AppConnectionState.connecting;
    _connectedDevice = device;
    notifyListeners();
    _addLog("Connecting to ${device.name} (${device.address})...");

    try {
      final conn = await _fbc.connect(device.address);
      if (conn != null && conn.isConnected) {
        _connection = conn;
        _connectionState = AppConnectionState.connected;
        _addLog("Connected to ${device.name}!");
        notifyListeners();

        // Listen for incoming data
        _inputSub = conn.input?.listen(
          (data) {
            final text = utf8.decode(data);
            _addLog("[RX] $text");
          },
          onError: (e) {
            _addLog("Connection input error: $e");
            _handleDisconnect();
          },
          onDone: () {
            _addLog("Connection closed by remote device.");
            _handleDisconnect();
          },
        );
      } else {
        throw Exception("Failed to establish RFCOMM connection.");
      }
    } catch (e) {
      _connectionState = AppConnectionState.error;
      _connectedDevice = null;
      _addLog("Connection failed: $e");
      notifyListeners();
    }
  }

  void _handleDisconnect() {
    _connection = null;
    _connectionState = AppConnectionState.disconnected;
    _connectedDevice = null;
    _inputSub?.cancel();
    _inputSub = null;
    _addLog("Disconnected.");
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    if (_connection != null) {
      _addLog("Disconnecting...");
      try {
        await _connection!.finish();
        _connection!.dispose();
      } catch (e) {
        _addLog("Error while closing connection: $e");
      }
      _handleDisconnect();
    }
  }

  @override
  Future<void> sendData(String data) async {
    if (_connection != null &&
        _connectionState == AppConnectionState.connected) {
      try {
        _connection!.writeString(data);
        _addLog("[TX] $data");
      } catch (e) {
        _addLog("Error sending data: $e");
      }
    } else {
      _addLog("Error: Not connected. Cannot send data: $data");
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logs.add("[$timestamp] $message");
    if (_logs.length > 150) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  @override
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _inputSub?.cancel();
    _adapterStateSub?.cancel();
    _connection?.dispose();
    super.dispose();
  }
}
