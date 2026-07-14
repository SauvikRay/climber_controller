import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/bluetooth_service.dart';
import '../theme/theme.dart';

class ConnectionScreen extends StatefulWidget {
  final VoidCallback onConnected;

  const ConnectionScreen({super.key, required this.onConnected});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Run initial checks and permission requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndInit();
    });
  }

  Future<void> _checkPermissionsAndInit() async {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    await btService.init();

    bool granted = await btService.requestPermissions();
    dev.log("Permissions granted==>$granted");
    setState(() => _permissionsGranted = granted);
    if (!granted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: RobotTheme.surfaceDark,
            title: const Text(
              "Permissions Required",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Bluetooth and location permissions are required for physical connection. Please allow them in App Settings.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: RobotTheme.neonCyan),
                ),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Open Settings",
                  style: TextStyle(color: RobotTheme.neonPurple),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleScan(BluetoothService btService) {
    if (btService.isScanning) {
      btService.stopScan();
      _radarController.stop();
      _pulseController.stop();
    } else {
      btService.startScan();
      _radarController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothService>(context);

    // Automatically navigate to controller screen if connected
    if (btService.connectionState == AppConnectionState.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onConnected();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Cyber space mesh/background decoration
          Positioned.fill(child: CustomPaint(painter: GridPainter())),

          // Glow decorations
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RobotTheme.neonPurple.withValues(alpha: 0.15),
                // blurRadius: 100,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RobotTheme.neonCyan.withValues(alpha: 0.12),
                // blurRadius: 90,
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Header Panel
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => RobotTheme
                                      .cyberGradient
                                      .createShader(bounds),
                                  child: Text(
                                    'ROBOT CORE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.0,
                                        ),
                                  ),
                                ),
                                Text(
                                  'ARDUINO BLUETOOTH CONTROLLER',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: RobotTheme.neonCyan,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            // Glass status indicator
                            Expanded(
                              child: _buildConnectionBadge(
                                btService.connectionState,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        if (!btService.isBluetoothOn)
                          Container(
                            margin: const EdgeInsets.only(top: 15),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bluetooth_disabled,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    "Bluetooth is turned off. Please enable Bluetooth on your device to connect.",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Radar scanning animation / Center element
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      height: 260,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (btService.isScanning) ...[
                            // Radar waves
                            AnimatedBuilder(
                              animation: _radarController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: List.generate(3, (index) {
                                    double progress =
                                        (_radarController.value + index / 3) %
                                        1.0;
                                    return Container(
                                      width: 240 * progress,
                                      height: 240 * progress,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: RobotTheme.neonCyan.withValues(
                                            alpha: 1.0 - progress,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),

                            // Sweeper line
                            AnimatedBuilder(
                              animation: _radarController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _radarController.value * 2 * math.pi,
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        center: Alignment.center,
                                        colors: [
                                          RobotTheme.neonCyan.withValues(
                                            alpha: 0.3,
                                          ),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.2, 1.0],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],

                          // Scanning Core Button
                          GestureDetector(
                            onTap: () {
                              if (!_permissionsGranted) {
                                _checkPermissionsAndInit();
                              } else {
                                _toggleScan(btService);
                              }
                            },
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                double scale =
                                    1.0 + (_pulseController.value * 0.05);
                                return Transform.scale(
                                  scale: btService.isScanning ? scale : 1.0,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: RobotTheme.surfaceDark,
                                  border: Border.all(
                                    color: btService.isScanning
                                        ? RobotTheme.neonTeal
                                        : RobotTheme.neonCyan,
                                    width: 3,
                                  ),
                                  boxShadow: btService.isScanning
                                      ? RobotTheme.tealGlow(radius: 20)
                                      : RobotTheme.cyanGlow(radius: 12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      btService.isScanning
                                          ? Icons.sensors
                                          : Icons.bluetooth_searching,
                                      color: Colors.white,
                                      size: 38,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      btService.isScanning
                                          ? 'SCANNING'
                                          : 'TAP TO SCAN',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Device Lists Section
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Paired devices title
                      if (btService.pairedDevices.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          "PAIRED DEVICES",
                          Icons.settings_bluetooth,
                        ),
                        const SizedBox(height: 10),
                        ...btService.pairedDevices.map(
                          (device) => _buildDeviceRow(device, btService),
                        ),
                        const SizedBox(height: 25),
                      ],

                      // Discovered devices title
                      _buildSectionHeader(
                        context,
                        "AVAILABLE DEVICES",
                        Icons.devices_other,
                        trailing: btService.isScanning
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    RobotTheme.neonCyan,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),

                      if (btService.scanResults.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          decoration: RobotTheme.glassCardDecoration(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.radar,
                                color: RobotTheme.textMuted,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                btService.isScanning
                                    ? "Scanning for hardware..."
                                    : "No devices discovered yet.\nStart scanning above.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: RobotTheme.textSecondary,
                                  height: 1.4,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...btService.scanResults.map(
                          (device) => _buildDeviceRow(device, btService),
                        ),

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: RobotTheme.neonCyan),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildConnectionBadge(AppConnectionState state) {
    Color badgeColor;
    String text;
    List<BoxShadow>? glow;

    switch (state) {
      case AppConnectionState.connected:
        badgeColor = RobotTheme.neonTeal;
        text = "CONNECTED";
        glow = RobotTheme.tealGlow(radius: 8, opacity: 0.4);
        break;
      case AppConnectionState.connecting:
        badgeColor = RobotTheme.neonOrange;
        text = "PAIRING";
        glow = RobotTheme.orangeGlow(radius: 8, opacity: 0.4);
        break;
      case AppConnectionState.error:
        badgeColor = Colors.redAccent;
        text = "OFFLINE ERR";
        glow = null;
        break;
      case AppConnectionState.disconnected:
        badgeColor = RobotTheme.textMuted;
        text = "OFFLINE";
        glow = null;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: glow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(
    AppBluetoothDevice device,
    BluetoothService btService,
  ) {
    bool isConnectingThis =
        btService.connectionState == AppConnectionState.connecting &&
        btService.connectedDevice?.address == device.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: RobotTheme.glassCardDecoration(
        borderColor: isConnectingThis
            ? RobotTheme.neonOrange.withValues(alpha: 0.5)
            : Colors.white10,
      ),
      child: Row(
        children: [
          // Device Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnectingThis
                  ? RobotTheme.neonOrange.withValues(alpha: 0.1)
                  : RobotTheme.neonCyan.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isConnectingThis
                    ? RobotTheme.neonOrange.withValues(alpha: 0.3)
                    : Colors.white10,
                width: 1,
              ),
            ),
            child: Icon(
              device.name.toLowerCase().contains("car") ||
                      device.name.toLowerCase().contains("bot")
                  ? Icons.smart_toy
                  : Icons.bluetooth,
              color: isConnectingThis
                  ? RobotTheme.neonOrange
                  : RobotTheme.neonCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Name and address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  device.address,
                  style: TextStyle(
                    color: RobotTheme.textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Action connect button
          if (isConnectingThis)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  RobotTheme.neonOrange,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed:
                  btService.connectionState == AppConnectionState.connecting
                  ? null
                  : () => btService.connect(device),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: RobotTheme.neonCyan.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
              ),
              child: const Text(
                "CONNECT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RobotTheme.neonCyan.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    const double step = 30.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
