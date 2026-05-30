import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 着色器版蓝色地球：球面贴图 + 云层 + 大气辉光 + 自转
class EarthSphere extends StatefulWidget {
  const EarthSphere({super.key});

  @override
  State<EarthSphere> createState() => _EarthSphereState();
}

class _EarthSphereState extends State<EarthSphere>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = createTicker((d) {
      setState(() => _time = d.inMilliseconds / 1000.0);
    })..start();
  }

  Future<void> _load() async {
    final p = await ui.FragmentProgram.fromAsset('shaders/earth.frag');
    if (mounted) setState(() => _shader = p.fragmentShader());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: _EarthPainter(_shader!, _time),
    );
  }
}

class _EarthPainter extends CustomPainter {
  _EarthPainter(this.shader, this.time);

  final ui.FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_EarthPainter old) => old.time != time;
}
