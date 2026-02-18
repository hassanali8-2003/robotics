import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TelemetryScreen(),
  ));
}

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  late WebSocketChannel channel;

  int battery = 0;
  String status = "Connecting...";
  String location = "Unknown";
  bool connected = false;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    // IMPORTANT: If you are running this on a physical device, replace
    // "localhost" with your computer's local IP address.
    const websocketUrl = "ws://10.186.103.20:8080";
    debugPrint("🔌 Attempting WebSocket connection to $websocketUrl...");

    channel = WebSocketChannel.connect(
      Uri.parse(websocketUrl),
    );

    channel.ready.then((_) {
      debugPrint("✅ WebSocket connection established.");
      if (mounted) {
        setState(() {
          connected = true;
          status = "Connected";
        });
      }
    });

    channel.stream.listen(
          (message) {
        debugPrint("📩 RAW MESSAGE RECEIVED: $message");
        debugPrint("📦 Type: ${message.runtimeType}");

        try {
          String decoded;

          if (message is String) {
            decoded = message;
            debugPrint("✔️ Message is already a String.");
          } else if (message is List<int>) {
            decoded = utf8.decode(message);
            debugPrint("✔️ Decoded message from List<int> to String.");
          } else {
            debugPrint("⚠️ Unknown message type. Ignored.");
            return;
          }

          debugPrint("🧾 Decoded JSON String: $decoded");

          final data = jsonDecode(decoded);

          debugPrint("📊 Parsed Data: $data");

          if (data["type"] == "telemetry") {
            debugPrint("✔️ Message type is 'telemetry'. Updating UI...");
            if (mounted) {
              setState(() {
                battery = data["battery"];
                status = data["status"];
                location = data["location"];
              });
            }

            debugPrint(
                "✅ UI Updated → Battery: $battery | Status: $status | Location: $location");
          } else {
            debugPrint("⚠️ Message type is not 'telemetry'. Ignored.");
          }
        } catch (e, stacktrace) {
          debugPrint("❌ Error processing message: $e");
          debugPrint("📚 Stacktrace: $stacktrace");
        }
      },
      onDone: () {
        debugPrint("🔴 WebSocket connection closed.");
        if (mounted) {
          setState(() {
            connected = false;
            status = "Offline";
          });
        }
      },
      onError: (error, stacktrace) {
        debugPrint("🚨 WebSocket Error: $error");
        debugPrint("📚 Stacktrace: $stacktrace");
        if (mounted) {
          setState(() {
            connected = false;
            status = "Error";
          });
        }
      },
      cancelOnError: true,
    );

    debugPrint("🔵 WebSocket channel created. Listening for connection and messages...");
  }


  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(25),
          width: 420,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ROBOT TELEMETRY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: connected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        connected ? "LIVE" : "OFFLINE",
                        style: TextStyle(
                          color: connected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  )
                ],
              ),

              const SizedBox(height: 30),

              /// BATTERY SECTION
              const Text(
                "Battery Level",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: battery / 100),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 14,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      battery > 60
                          ? Colors.green
                          : battery > 30
                          ? Colors.orange
                          : Colors.red,
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              Text(
                "$battery %",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              /// STATUS SECTION
              telemetryCard(
                icon: Icons.settings_remote,
                title: "Robot Status",
                value: status.toUpperCase(),
                color: status == "working"
                    ? Colors.orange
                    : status == "standing"
                    ? Colors.blue
                    : Colors.green,
              ),

              const SizedBox(height: 20),

              /// LOCATION SECTION
              telemetryCard(
                icon: Icons.location_on,
                title: "Current Location",
                value: location.toUpperCase(),
                color: Colors.purpleAccent,
              ),

              const SizedBox(height: 20),

              /// TIMESTAMP
              Text(
                "Last update: ${DateTime.now().toLocal().toString().split('.')[0]}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget telemetryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }



  Widget infoBox(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 6),
        Text(
          value.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
