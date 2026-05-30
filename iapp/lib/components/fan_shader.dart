import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 着色器风扇：5 叶涡轮 + 中心轴心 + 旋转
class FanShader extends StatefulWidget {
  const FanShader({
    super.key,
    required this.color,
    this.speed = 1.0,
  });

  /// 主色（叶片）
  final Color color;

  /// 转速倍率
  final double speed;

  @override
  State<FanShader> createState() => _FanShaderState();
}

class _FanShaderState extends State<FanShader>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = createTicker((d) {
      setState(() => _time = d.inMilliseconds / 1000.0 * widget.speed);
    })..start();
  }

  Future<void> _load() async {
    final p = await ui.FragmentProgram.fromAsset('shaders/fan.frag');
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
      painter: _FanPainter(_shader!, _time, widget.color),
    );
  }
}

class _FanPainter extends CustomPainter {
  _FanPainter(this.shader, this.time, this.color);

  final ui.FragmentShader shader;
  final double time;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      // 颜色四通道（Flutter 3.27+ 用 r/g/b/a，0-1 范围）
      ..setFloat(3, color.r)
      ..setFloat(4, color.g)
      ..setFloat(5, color.b)
      ..setFloat(6, color.a);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_FanPainter old) =>
      old.time != time || old.color != color;
}
