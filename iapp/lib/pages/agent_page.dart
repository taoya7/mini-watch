import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMilliseconds / 1000.0);
    })..start();
  }

  Future<void> _load() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/agent_crt.frag',
    );
    if (mounted) setState(() => _shader = program.fragmentShader());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02110A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_shader != null)
            CustomPaint(painter: _AgentCrtPainter(_shader!, _time)),
          const _CrtGlassOverlay(),
        ],
      ),
    );
  }
}

class _AgentCrtPainter extends CustomPainter {
  _AgentCrtPainter(this.shader, this.time);

  final ui.FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, 1.0)
      ..setFloat(4, 1.0)
      ..setFloat(5, 1.0)
      ..setFloat(6, 1.0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_AgentCrtPainter oldDelegate) => oldDelegate.time != time;
}

class _CrtGlassOverlay extends StatelessWidget {
  const _CrtGlassOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.16),
            ],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
        child: CustomPaint(painter: _ScanlinePainter()),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (double y = 1; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
