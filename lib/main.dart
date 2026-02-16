import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: VideoStreamPage(),
      );
}

class VideoStreamPage extends StatefulWidget {
  const VideoStreamPage({super.key});

  @override
  State<VideoStreamPage> createState() => _VideoStreamPageState();
}

class _VideoStreamPageState extends State<VideoStreamPage> {
  late WebSocketChannel channel;
  Uint8List? currentFrame;

  @override
  void initState() {
    super.initState();
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Set full-screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    try {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://172.23.200.150:8080'),
      );

      channel.stream.listen(
        (message) {
          if (message is Uint8List) {
            setState(() {
              currentFrame = message;
            });
          }
        },
        onError: (error) => print('WebSocket error: $error'),
        onDone: () => print('WebSocket connection closed.'),
        cancelOnError: true,
      );
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

  @override
  void dispose() {
    // Restore default orientations
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    // Restore default UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Stream
          Center(
            child: currentFrame != null
                ? Image.memory(
                    currentFrame!,
                    gaplessPlayback: true,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : const CircularProgressIndicator(),
          ),
          // Joystick
          Align(
            alignment: const Alignment(0.8, 0.7),
            child: SizedBox(
              width: 150,
              height: 150,
              child: Joystick(
                listener: (details) {
                  // Handle joystick movement
                  print('Joystick: x=${details.x.toStringAsFixed(2)}, y=${details.y.toStringAsFixed(2)}');
                },
                stick: JoystickStick(
                    decoration: JoystickStickDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.5),

                )),
                base: JoystickBase(
                    decoration: JoystickBaseDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.3),

                )),
              ),
            ),
          ),
          // Icon Buttons
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
                    onPressed: () {
                      print('Flash button pressed');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                    onPressed: () {
                      print('Camera button pressed');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.white, size: 32),
                    onPressed: () {
                      print('Video button pressed');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
