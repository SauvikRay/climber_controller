import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  bool get isSimulation;
  AppConnectionState get connectionState;
  List<AppBluetoothDevice> get scanResults;
  List<AppBluetoothDevice> get pairedDevices;
  bool get isScanning;
  AppBluetoothDevice? get connectedDevice;
  List<String> get logs;

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

  @override
  bool get isSimulation => false;

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
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    _addLog("Permissions status: $statuses. Granted? $allGranted");
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
    _connection?.dispose();
    super.dispose();
  }
}

class SimulationBluetoothService extends BluetoothService {
  AppConnectionState _connectionState = AppConnectionState.disconnected;
  final List<AppBluetoothDevice> _scanResults = [];
  final List<AppBluetoothDevice> _pairedDevices = [];
  bool _isScanning = false;
  AppBluetoothDevice? _connectedDevice;
  final List<String> _logs = [];
  Timer? _scanTimer;
  Timer? _connectTimer;

  @override
  bool get isSimulation => true;

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
  Future<void> init() async {
    // _pairedDevices.addAll([
    //   AppBluetoothDevice(name: 'HC-05_Robot_Car', address: '00:18:E4:34:C2:A8', isPaired: true),
    //   AppBluetoothDevice(name: 'Arduino_BT_Shield', address: '98:D3:31:F4:12:45', isPaired: true),
    // ]);
  }

  @override
  Future<bool> requestPermissions() async {
    _addLog("Simulator: Requesting Bluetooth permissions (Simulated success)");
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }

  @override
  Future<void> startScan() async {
    _scanResults.clear();
    _isScanning = true;
    _addLog("Simulator: Starting discovery scan...");
    notifyListeners();

    _scanTimer?.cancel();
    int count = 0;
    final mockDevices = [
      // AppBluetoothDevice(
      //   name: 'Arduino_Neo_Bot',
      //   address: '20:19:08:11:F2:BC',
      //   rssi: -55,
      // ),
      // AppBluetoothDevice(
      //   name: 'Crawler_Robot_3000',
      //   address: 'AC:22:0B:4F:9E:11',
      //   rssi: -72,
      // ),
      // AppBluetoothDevice(
      //   name: 'HC-06_Obstacle_Car',
      //   address: '00:19:D4:21:44:A2',
      //   rssi: -65,
      // ),
      // AppBluetoothDevice(
      //   name: 'Smart_Clean_Bot',
      //   address: 'FE:89:12:3C:A9:74',
      //   rssi: -85,
      // ),
    ];

    _scanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (count < mockDevices.length) {
        _scanResults.add(mockDevices[count]);
        _addLog("Simulator: Discovered device ${mockDevices[count].name}");
        notifyListeners();
        count++;
      } else {
        stopScan();
      }
    });
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _isScanning = false;
    _addLog("Simulator: Scan stopped.");
    notifyListeners();
  }

  @override
  Future<void> connect(AppBluetoothDevice device) async {
    await stopScan();
    _connectionState = AppConnectionState.connecting;
    _connectedDevice = device;
    _addLog("Simulator: Connecting to ${device.name}...");
    notifyListeners();

    _connectTimer?.cancel();
    _connectTimer = Timer(const Duration(milliseconds: 1500), () {
      // Simulate 95% connection success rate
      final success = Random().nextDouble() < 0.95;
      if (success) {
        _connectionState = AppConnectionState.connected;
        _addLog(
          "Simulator: Connected to ${device.name} (Simulated Protocol: SPP/RFCOMM)",
        );
        // Trigger a friendly greeting from the simulated Arduino robot
        _addLog("[RX] ROBOT READY. SEND COMMANDS.");
      } else {
        _connectionState = AppConnectionState.error;
        _connectedDevice = null;
        _addLog("Simulator: Connection timed out.");
      }
      notifyListeners();
    });
  }

  @override
  Future<void> disconnect() async {
    _connectTimer?.cancel();
    _addLog("Simulator: Disconnecting from ${_connectedDevice?.name}...");
    _connectionState = AppConnectionState.disconnected;
    _connectedDevice = null;
    notifyListeners();
  }

  @override
  Future<void> sendData(String data) async {
    if (_connectionState == AppConnectionState.connected) {
      _addLog("[TX] $data");

      // Simulated response depending on command
      Future.delayed(const Duration(milliseconds: 200), () {
        if (data == 'F') {
          _addLog("[RX] ACK: Moving Forward");
        } else if (data == 'B') {
          _addLog("[RX] ACK: Moving Backward");
        } else if (data == 'L') {
          _addLog("[RX] ACK: Steering Left");
        } else if (data == 'R') {
          _addLog("[RX] ACK: Steering Right");
        } else if (data == 'S') {
          _addLog("[RX] ACK: All Motors Stopped");
        } else if (data.startsWith('S:')) {
          _addLog("[RX] ACK: Speed updated to ${data.substring(2)}%");
        }
      });
    } else {
      _addLog("Simulator: Cannot send. Not connected.");
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
    _scanTimer?.cancel();
    _connectTimer?.cancel();
    super.dispose();
  }
}
