import 'package:flutter/material.dart';

/// 颜色风格模型 — 所有页面颜色都来自这里
class AppTheme {
  const AppTheme({
    required this.id,
    required this.name,
    required this.bg,
    required this.card,
    required this.accent,
    required this.accentSoft,
    required this.ok,
    required this.warn,
    required this.danger,
    required this.textMain,
    required this.textSub,
    required this.textDim,
  });

  final String id;
  final String name;
  final Color bg;
  final Color card;
  final Color accent;
  final Color accentSoft;
  final Color ok;
  final Color warn;
  final Color danger;
  final Color textMain;
  final Color textSub;
  final Color textDim;
}
