import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../theme/theme.dart';

class ControllerScreen extends StatefulWidget {
  final VoidCallback onDisconnected;

  const ControllerScreen({super.key, required this.onDisconnected});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  // Command Mapping Configuration
  String cmdForward = 'F';
  String cmdBackward = 'B';
  String cmdLeft = 'L';
  String cmdRight = 'R';
  String cmdStop = 'S';
  String cmdHornOn = 'H';
  String cmdHornOff = 'h';

  bool headlightsOn = false;
  double speedPercentage = 50;
  final ScrollController _scrollController = ScrollController();
  bool autoScroll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendAction(BluetoothService service, String command) {
    service.sendData(command);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _toggleHeadlights(BluetoothService service) {
    setState(() {
      headlightsOn = !headlightsOn;
    });
    _sendAction(service, headlightsOn ? 'W' : 'w');
  }

  void _updateSpeed(BluetoothService service, double val) {
    setState(() {
      speedPercentage = val;
    });
    // Send speed command, e.g. "S:75"
    _sendAction(service, "S:${val.round()}");
  }

  void _showSettingsDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RobotTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.tune, color: RobotTheme.neonCyan),
                          SizedBox(width: 10),
                          Text(
                            "COMMAND MAPPINGS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  const Text(
                    "Assign what characters are sent to the Arduino when each button is pressed:",
                    style: TextStyle(
                      color: RobotTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Command fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildConfigField("Forward", cmdForward, (val) {
                          setState(() => cmdForward = val);
                          setModalState(() => cmdForward = val);
                        }),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildConfigField("Backward", cmdBackward, (
                          val,
                        ) {
                          setState(() => cmdBackward = val);
                          setModalState(() => cmdBackward = val);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildConfigField("Steer Left", cmdLeft, (val) {
                          setState(() => cmdLeft = val);
                          setModalState(() => cmdLeft = val);
                        }),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildConfigField("Steer Right", cmdRight, (
                          val,
                        ) {
                          setState(() => cmdRight = val);
                          setModalState(() => cmdRight = val);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildConfigField("Release Stop", cmdStop, (
                          val,
                        ) {
                          setState(() => cmdStop = val);
                          setModalState(() => cmdStop = val);
                        }),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildConfigField("Horn Toggle", cmdHornOn, (
                          val,
                        ) {
                          setState(() => cmdHornOn = val);
                          setModalState(() => cmdHornOn = val);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Reset defaults
                        setState(() {
                          cmdForward = 'F';
                          cmdBackward = 'B';
                          cmdLeft = 'L';
                          cmdRight = 'R';
                          cmdStop = 'S';
                          cmdHornOn = 'H';
                          cmdHornOff = 'h';
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(
                          alpha: 0.1,
                        ),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "RESET TO DEFAULTS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfigField(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: value.length),
            ),
          onChanged: onChanged,
          maxLength: 5,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RobotTheme.neonCyan),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothService>(context);

    // If suddenly disconnected, pop back to home connection page
    if (btService.connectionState == AppConnectionState.disconnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDisconnected();
      });
    }

    return Scaffold(
      backgroundColor: RobotTheme.spaceDark,
      appBar: AppBar(
        title: Text(
          btService.connectedDevice?.name ?? 'CONTROL ROOM',
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RobotTheme.neonCyan),
          onPressed: () => btService.disconnect(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: RobotTheme.neonCyan),
            onPressed: () => _showSettingsDrawer(context),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () => btService.disconnect(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isLandscape = constraints.maxWidth > constraints.maxHeight;

            if (isLandscape) {
              return Row(
                children: [
                  // Left Side: D-Pad & Controls
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildControllerInterface(btService),
                          const SizedBox(height: 20),
                          _buildSpeedSlider(btService),
                        ],
                      ),
                    ),
                  ),

                  // Right Side: Terminal Log
                  Expanded(
                    flex: 4,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      child: _buildTerminalLog(btService),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  // Top Panel: Speed and Auxiliary controllers
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Headlight Toggle
                        _buildToggleButton(
                          icon: headlightsOn
                              ? Icons.light_mode
                              : Icons.light_mode_outlined,
                          label: headlightsOn ? "LIGHTS ON" : "LIGHTS OFF",
                          isActive: headlightsOn,
                          onPressed: () => _toggleHeadlights(btService),
                          activeColor: RobotTheme.neonAmber,
                          glow: headlightsOn
                              ? RobotTheme.orangeGlow(radius: 8)
                              : null,
                        ),
                        // Simulated/Real Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: btService.isSimulation
                                ? RobotTheme.neonPurple.withValues(alpha: 0.1)
                                : RobotTheme.neonTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: btService.isSimulation
                                  ? RobotTheme.neonPurple
                                  : RobotTheme.neonTeal,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            btService.isSimulation
                                ? "MOCK SIMULATOR"
                                : "PHYSICAL HARDWARE",
                            style: TextStyle(
                              color: btService.isSimulation
                                  ? RobotTheme.neonPurple
                                  : RobotTheme.neonTeal,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        // Horn Trigger Button
                        Listener(
                          onPointerDown: (_) =>
                              _sendAction(btService, cmdHornOn),
                          onPointerUp: (_) =>
                              _sendAction(btService, cmdHornOff),
                          child: _buildToggleButton(
                            icon: Icons.volume_up,
                            label: "HORN HELD",
                            isActive: false,
                            onPressed: () {},
                            activeColor: RobotTheme.neonCyan,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center: Steer D-Pad Controller
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _buildControllerInterface(btService),
                      ),
                    ),
                  ),

                  // Speed Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 5,
                    ),
                    child: _buildSpeedSlider(btService),
                  ),

                  const SizedBox(height: 10),

                  // Bottom: Live Serial Log Terminal
                  Expanded(flex: 4, child: _buildTerminalLog(btService)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required Color activeColor,
    List<BoxShadow>? glow,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive
            ? activeColor.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.02),
        side: BorderSide(
          color: isActive ? activeColor : Colors.white24,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? activeColor : RobotTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : RobotTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSlider(BluetoothService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: RobotTheme.glassCardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.speed, color: RobotTheme.neonCyan, size: 20),
          const SizedBox(width: 12),
          Text(
            "SPEED: ${speedPercentage.round()}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: RobotTheme.neonCyan,
                inactiveTrackColor: Colors.white12,
                thumbColor: RobotTheme.neonCyan,
                overlayColor: RobotTheme.neonCyan.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: speedPercentage,
                min: 0,
                max: 100,
                divisions: 10,
                onChanged: (val) {
                  setState(() {
                    speedPercentage = val;
                  });
                },
                onChangeEnd: (val) => _updateSpeed(service, val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerInterface(BluetoothService service) {
    // Beautiful round virtual steering layout
    return LayoutBuilder(
      builder: (context, c) {
        double diameter = math.min(c.maxHeight * 0.9, 240.0);
        if (diameter < 180) diameter = 180;

        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.01),
            border: Border.all(
              color: RobotTheme.neonCyan.withValues(alpha: 0.15),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner circular ring
              Center(
                child: Container(
                  width: diameter * 0.6,
                  height: diameter * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: RobotTheme.neonPurple.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Center Stop Indicator Badge
              Center(
                child: Container(
                  width: diameter * 0.3,
                  height: diameter * 0.3,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: RobotTheme.surfaceDark,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.stop,
                      color: Colors.redAccent.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Directional Buttons (F, B, L, R)

              // Forward Button (Top)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildTactileButton(
                    service: service,
                    command: cmdForward,
                    icon: Icons.keyboard_arrow_up,
                    glowShadows: RobotTheme.cyanGlow(radius: 8),
                  ),
                ),
              ),

              // Backward Button (Bottom)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildTactileButton(
                    service: service,
                    command: cmdBackward,
                    icon: Icons.keyboard_arrow_down,
                    glowShadows: RobotTheme.cyanGlow(radius: 8),
                  ),
                ),
              ),

              // Left Button (Left)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildTactileButton(
                    service: service,
                    command: cmdLeft,
                    icon: Icons.keyboard_arrow_left,
                    glowShadows: RobotTheme.purpleGlow(radius: 8),
                  ),
                ),
              ),

              // Right Button (Right)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildTactileButton(
                    service: service,
                    command: cmdRight,
                    icon: Icons.keyboard_arrow_right,
                    glowShadows: RobotTheme.purpleGlow(radius: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTactileButton({
    required BluetoothService service,
    required String command,
    required IconData icon,
    required List<BoxShadow> glowShadows,
  }) {
    // We use a custom stateful button to capture press down & release states
    return _TactileButton(
      icon: icon,
      glowShadows: glowShadows,
      onPressStart: () {
        _sendAction(service, command);
      },
      onPressEnd: () {
        _sendAction(service, cmdStop);
      },
    );
  }

  Widget _buildTerminalLog(BluetoothService service) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF04060E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.terminal, color: RobotTheme.neonTeal, size: 14),
                    SizedBox(width: 8),
                    Text(
                      "SERIAL PORT TERMINAL",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: RobotTheme.neonTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Auto scroll toggle
                    IconButton(
                      icon: Icon(
                        Icons.swap_vert,
                        color: autoScroll
                            ? RobotTheme.neonCyan
                            : Colors.white24,
                        size: 14,
                      ),
                      tooltip: "Auto Scroll",
                      onPressed: () {
                        setState(() {
                          autoScroll = !autoScroll;
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    // Clear logs
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white54,
                        size: 14,
                      ),
                      tooltip: "Clear Terminal",
                      onPressed: () => service.clearLogs(),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logs view
          Expanded(
            child: service.logs.isEmpty
                ? const Center(
                    child: Text(
                      "No console data. Hold controller keys to send commands.",
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: service.logs.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final log = service.logs[index];
                      Color color = RobotTheme.textSecondary;
                      if (log.contains("[TX]")) {
                        color = RobotTheme.neonCyan;
                      } else if (log.contains("[RX]")) {
                        color = RobotTheme.neonTeal;
                      } else if (log.contains("failed") ||
                          log.contains("Error")) {
                        color = Colors.redAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TactileButton extends StatefulWidget {
  final IconData icon;
  final List<BoxShadow> glowShadows;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  const _TactileButton({
    required this.icon,
    required this.glowShadows,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  State<_TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<_TactileButton> {
  bool _isPressed = false;

  void _handlePressStart() {
    if (!_isPressed) {
      setState(() => _isPressed = true);
      widget.onPressStart();
    }
  }

  void _handlePressEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      widget.onPressEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) => _handlePressStart(),
      onPanCancel: () => _handlePressEnd(),
      onPanEnd: (_) => _handlePressEnd(),
      onTapDown: (_) => _handlePressStart(),
      onTapUp: (_) => _handlePressEnd(),
      onTapCancel: () => _handlePressEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.white.withValues(alpha: 0.05)
              : RobotTheme.surfaceDark,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isPressed ? Colors.white : Colors.white12,
            width: _isPressed ? 2.5 : 1.5,
          ),
          boxShadow: _isPressed ? widget.glowShadows : null,
        ),
        child: Icon(
          widget.icon,
          color: _isPressed ? Colors.white : RobotTheme.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}
