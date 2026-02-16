import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class Robot3DView extends StatefulWidget {
  @override
  State<Robot3DView> createState() => _Robot3DViewState();
}

class _Robot3DViewState extends State<Robot3DView> {

  final Flutter3DController controller = Flutter3DController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Robot Controller")),
      body: Flutter3DViewer(
        src: "assets/Character.glb",
        controller: controller,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.startRotation(rotationSpeed: 23);// rotate robot
        },
        child: Icon(Icons.rotate_right),
      ),
    );
  }
}
