import 'package:flutter/material.dart';
import '../styles/app_theme.dart';
import '../styles/theme_controller.dart';
import '../styles/theme_scope.dart';
import '../styles/themes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 12,
        toolbarHeight: 44,
        title: Text(
          '设置',
          style: TextStyle(
            color: context.theme.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: context.theme.textMain, size: 20),
      ),
      body: SafeArea(
        // top 已由 AppBar 处理，剩下三边避开横屏刘海 / 底部 home indicator
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(text: '主题色'),
              const SizedBox(height: 8),
              // Wrap 自适应：宽屏每行装更多，窄屏自动换行
              ListenableBuilder(
                listenable: themeController,
                builder: (_, __) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in appThemes)
                      _ThemeChip(
                        theme: t,
                        selected: t.id == themeController.current.id,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel(text: '关于'),
              const SizedBox(height: 8),
              _AboutBox(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 小节标题 ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: context.theme.textSub,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─── 主题芯片：紧凑横向 chip ─────────────────────────────────────

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.theme, required this.selected});

  final AppTheme theme;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => themeController.setTheme(theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.accent
                : Colors.white.withValues(alpha: 0.04),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 主色圆点
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: theme.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.accent.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 名字
            Text(
              theme.name,
              style: TextStyle(
                color: theme.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            // 选中标记
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, color: theme.accent, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 关于信息 ──────────────────────────────────────────────────────

class _AboutBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _row(context, '版本', 'v1.0.0'),
          const SizedBox(height: 8),
          _row(context, '构建', '1'),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) => Row(
    children: [
      Text(k, style: TextStyle(color: context.theme.textSub, fontSize: 12)),
      const Spacer(),
      Text(
        v,
        style: TextStyle(
          color: context.theme.textMain,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}
