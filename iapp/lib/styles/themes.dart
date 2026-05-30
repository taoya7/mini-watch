import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 暖琥珀（默认）
const themeAmber = AppTheme(
  id: 'amber',
  name: '暖琥珀',
  bg: Color(0xFF181510),
  card: Color(0xFF221C12),
  accent: Color(0xFFE5A04C),
  accentSoft: Color(0x33E5A04C),
  ok: Color(0xFF7EC97A),
  warn: Color(0xFFE5A04C),
  danger: Color(0xFFE56B4C),
  textMain: Color(0xFFF5EBDC),
  textSub: Color(0xFFB0A085),
  textDim: Color(0xFF7A6F5A),
);

/// 深海蓝
const themeOcean = AppTheme(
  id: 'ocean',
  name: '深海',
  bg: Color(0xFF0A1220),
  card: Color(0xFF121B2D),
  accent: Color(0xFF64D2FF),
  accentSoft: Color(0x3364D2FF),
  ok: Color(0xFF30D158),
  warn: Color(0xFFFFD60A),
  danger: Color(0xFFFF453A),
  textMain: Color(0xFFEAF2FF),
  textSub: Color(0xFF8FA1BD),
  textDim: Color(0xFF5A6B85),
);

/// 森林绿
const themeForest = AppTheme(
  id: 'forest',
  name: '森林',
  bg: Color(0xFF0D1812),
  card: Color(0xFF142217),
  accent: Color(0xFF7EC97A),
  accentSoft: Color(0x337EC97A),
  ok: Color(0xFF7EC97A),
  warn: Color(0xFFE5C77A),
  danger: Color(0xFFE56B4C),
  textMain: Color(0xFFEAF5E5),
  textSub: Color(0xFF99B098),
  textDim: Color(0xFF5F7560),
);

/// 碳灰
const themeCarbon = AppTheme(
  id: 'carbon',
  name: '碳灰',
  bg: Color(0xFF0E1014),
  card: Color(0xFF181B22),
  accent: Color(0xFFB388FF),
  accentSoft: Color(0x33B388FF),
  ok: Color(0xFF30D158),
  warn: Color(0xFFFF9F0A),
  danger: Color(0xFFFF453A),
  textMain: Color(0xFFF0F2F7),
  textSub: Color(0xFF9099AA),
  textDim: Color(0xFF5A6273),
);

/// 樱花粉
const themeSakura = AppTheme(
  id: 'sakura',
  name: '樱花',
  bg: Color(0xFF1A0F14),
  card: Color(0xFF26161D),
  accent: Color(0xFFFF8AA8),
  accentSoft: Color(0x33FF8AA8),
  ok: Color(0xFFA3DDA3),
  warn: Color(0xFFFFCE7A),
  danger: Color(0xFFFF5C6B),
  textMain: Color(0xFFFFEEF2),
  textSub: Color(0xFFBE9AA8),
  textDim: Color(0xFF7A5E68),
);

const appThemes = <AppTheme>[
  themeAmber,
  themeOcean,
  themeForest,
  themeCarbon,
  themeSakura,
];
