import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: VideoStreamPage());
}

class VideoStreamPage extends StatefulWidget {
  @override
  State<VideoStreamPage> createState() => _VideoStreamPageState();
}

class _VideoStreamPageState extends State<VideoStreamPage> {
  late WebSocketChannel channel;
  Uint8List? currentFrame;
  String logText = 'Connecting to server...\n';

  @override
  void initState() {
    super.initState();

    try {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://172.23.200.150:8080'),
      );

      log('WebSocket connected.');

      channel.stream.listen(
        (message) {
          try {
            // The message should be binary data (Uint8List).
            if (message is Uint8List) {
              setState(() {
                currentFrame = message;
              });
            } else {
                // Log if we receive unexpected text data
                log('Received non-binary message: $message');
            }
          } catch (e) {
            log('Error processing frame: $e');
          }
        },
        onError: (error) => log('WebSocket error: $error'),
        onDone: () => log('WebSocket connection closed.'),
        cancelOnError: true,
      );
    } catch (e) {
      log('Failed to connect: $e');
    }
  }

  void log(String message) {
    print(message);
    setState(() {
      logText += message + '\n';
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Video Stream')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: currentFrame != null
                  ? Image.memory(currentFrame!, gaplessPlayback: true) // gaplessPlayback for smoother transitions
                  : const Text('Waiting for video...'),
            ),
          ),
          Divider(),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Text(
                  logText,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
