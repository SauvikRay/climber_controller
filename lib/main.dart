import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/bluetooth_service.dart';
import 'screens/connection_screen.dart';
import 'screens/controller_screen.dart';
import 'theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late BluetoothService _btService;

  @override
  void initState() {
    super.initState();
    _btService = PhysicalBluetoothService();
    _btService.init();
  }

  @override
  void dispose() {
    _btService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BluetoothService>.value(
      value: _btService,
      child: MaterialApp(
        title: 'Arduino Controller',
        theme: RobotTheme.themeData,
        debugShowCheckedModeBanner: false,
        home: Consumer<BluetoothService>(
          builder: (context, service, _) {
            // Reactive Routing:
            // If connected, show the dashboard controller workspace.
            // If disconnected/connecting/error, show the bluetooth config list workspace.
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: service.connectionState == AppConnectionState.connected
                  ? ControllerScreen(
                      key: const ValueKey('controller_screen'),
                      onDisconnected: () {
                        // Optional side-effects on disconnect
                      },
                    )
                  : ConnectionScreen(
                      key: const ValueKey('connection_screen'),
                      onConnected: () {
                        // Handled reactively by the Consumer builder
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}
