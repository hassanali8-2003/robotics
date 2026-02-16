import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RobotGameScreen(),
  ));
}

class RobotGameScreen extends StatefulWidget {
  const RobotGameScreen({super.key});

  @override
  State<RobotGameScreen> createState() => _RobotGameScreenState();
}

class _RobotGameScreenState extends State<RobotGameScreen> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();

  StreamSubscription? _gyroSubscription;

  // Gyro values
  double gyroX = 0;
  double gyroY = 0;

  // Joystick values
  double joystickPan = 0;
  double joystickTilt = 0;

  // Final camera values
  double cameraPan = 0;
  double cameraTilt = 0;

  @override
  void initState() {
    super.initState();
    initCamera();
    startGyro();
  }

  // =========================
  // CAMERA INIT (Back Camera)
  // =========================
  Future<void> initCamera() async {
    await _renderer.initialize();

    MediaStream stream =
    await navigator.mediaDevices.getUserMedia({
      'video': {
        'facingMode': 'environment', // BACK CAMERA
      },
      'audio': false,
    });

    _renderer.srcObject = stream;

    setState(() {});
  }

  // =========================
  // GYRO START
  // =========================
  void startGyro() {
    _gyroSubscription = gyroscopeEvents.listen((event) {
      gyroX = event.y;
      gyroY = event.x;

      updateCameraControl();
    });
  }

  // =========================
  // JOYSTICK LISTENER
  // =========================
  void onJoystickChanged(StickDragDetails details) {
    joystickPan = details.x;
    joystickTilt = details.y;

    updateCameraControl();
  }

  // =========================
  // CONTROL LOGIC
  // =========================
  void updateCameraControl() {
    cameraPan =
        (joystickPan * 60) + (gyroX * 15);

    cameraTilt =
        (joystickTilt * 60) + (gyroY * 15);

    // Clamp range
    cameraPan = cameraPan.clamp(-100, 100);
    cameraTilt = cameraTilt.clamp(-100, 100);

    sendToRobot(cameraPan, cameraTilt);
  }

  // =========================
  // ROBOT COMMAND SENDER
  // =========================
  void sendToRobot(double pan, double tilt) {
    // Replace with WebSocket later
    debugPrint("PAN: ${pan.toStringAsFixed(2)}  TILT: ${tilt.toStringAsFixed(2)}");
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _renderer.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// FULLSCREEN VIDEO BACKGROUND
          Positioned.fill(
            child: _renderer.srcObject != null
                ? RTCVideoView(
              _renderer,
              objectFit:
              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
                : const Center(child: CircularProgressIndicator()),
          ),

          /// DARK GAMING OVERLAY
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
            ),
          ),

          /// LEFT JOYSTICK (Movement)
          Positioned(
            bottom: 40,
            left: 40,
            child: Joystick(
              mode: JoystickMode.all,
              listener: onJoystickChanged,
            ),
          ),

          /// RIGHT JOYSTICK (Camera Control)
          Positioned(
            bottom: 40,
            right: 40,
            child: Joystick(
              mode: JoystickMode.all,
              listener: onJoystickChanged,
            ),
          ),

          /// STATUS BAR
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                statusBox("CONNECTED", Colors.green),
                statusBox("CAM: BACK", Colors.white),
                statusBox("GYRO ACTIVE", Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget statusBox(String text, Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
