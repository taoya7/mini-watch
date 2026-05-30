import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 单个红绿灯：着色器版，含复古颗粒 / 扫描线 / 球面光
class LightShader extends StatefulWidget {
  const LightShader({
    super.key,
    required this.color,
    this.intensity = 1.0,
  });

  final Color color;

  /// 亮度 0..1：0=熄灭(留暗玻璃感)，1=全亮；中间值用于呼吸
  final double intensity;

  @override
  State<LightShader> createState() => _LightShaderState();
}

class _LightShaderState extends State<LightShader>
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
    final p = await ui.FragmentProgram.fromAsset('shaders/traffic_light.frag');
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
      painter: _LightPainter(
        shader: _shader!,
        time: _time,
        color: widget.color,
        intensity: widget.intensity,
      ),
    );
  }
}

class _LightPainter extends CustomPainter {
  _LightPainter({
    required this.shader,
    required this.time,
    required this.color,
    required this.intensity,
  });

  final ui.FragmentShader shader;
  final double time;
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, color.r)
      ..setFloat(4, color.g)
      ..setFloat(5, color.b)
      ..setFloat(6, color.a)
      ..setFloat(7, intensity.clamp(0.0, 1.0));
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_LightPainter old) =>
      old.time != time ||
      old.color != color ||
      old.intensity != intensity;
}
