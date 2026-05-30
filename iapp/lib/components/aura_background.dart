import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// 点阵波浪 + 四周呼吸辉光背景（GLSL）
/// 用法：放在 Stack 最底层，上面叠页面内容
class AuraBackground extends StatefulWidget {
  const AuraBackground({super.key, required this.color});

  /// 主色：决定点阵 / 边缘光晕色调（红绿灯页传当前状态色）
  final Color color;

  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  ui.Image? _perlin;
  ui.Image? _perlin2;
  ui.Image? _blueNoise;
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
    final results = await Future.wait<Object>([
      ui.FragmentProgram.fromAsset('shaders/aura_bg.frag'),
      _loadImage('assets/spellverse/perlinnoise.webp'),
      _loadImage('assets/spellverse/perlinnoise2.webp'),
      _loadImage('assets/spellverse/bluenoise.webp'),
    ]);
    if (!mounted) return;
    final program = results[0] as ui.FragmentProgram;
    setState(() {
      _shader = program.fragmentShader();
      _perlin = results[1] as ui.Image;
      _perlin2 = results[2] as ui.Image;
      _blueNoise = results[3] as ui.Image;
    });
  }

  Future<ui.Image> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _perlin?.dispose();
    _perlin2?.dispose();
    _blueNoise?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    final perlin = _perlin;
    final perlin2 = _perlin2;
    final blueNoise = _blueNoise;
    if (shader == null ||
        perlin == null ||
        perlin2 == null ||
        blueNoise == null) {
      // shader 未就绪时给个纯色兜底，避免闪白
      return ColoredBox(color: Color.lerp(Colors.black, widget.color, 0.04)!);
    }
    return CustomPaint(
      size: Size.infinite,
      painter: _AuraPainter(
        shader: shader,
        time: _time,
        color: widget.color,
        perlin: perlin,
        perlin2: perlin2,
        blueNoise: blueNoise,
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  _AuraPainter({
    required this.shader,
    required this.time,
    required this.color,
    required this.perlin,
    required this.perlin2,
    required this.blueNoise,
  });

  final ui.FragmentShader shader;
  final double time;
  final Color color;
  final ui.Image perlin;
  final ui.Image perlin2;
  final ui.Image blueNoise;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, color.r)
      ..setFloat(4, color.g)
      ..setFloat(5, color.b)
      ..setImageSampler(0, perlin)
      ..setImageSampler(1, perlin2)
      ..setImageSampler(2, blueNoise);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_AuraPainter old) =>
      old.time != time || old.color != color;
}
