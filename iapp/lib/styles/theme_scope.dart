import 'package:flutter/widgets.dart';
import 'app_theme.dart';

/// 把当前主题注入子树。
/// 用 InheritedWidget 让 `context.dependOnInheritedWidgetOfExactType` 注册依赖，
/// 主题切换时被注册的 Element 全部标脏 → 即使是 const widget 也会重建。
class ThemeScope extends InheritedWidget {
  const ThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final AppTheme theme;

  static AppTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null,
        'ThemeScope.of(context) 调用前请确保上层有 ThemeScope');
    return scope!.theme;
  }

  @override
  bool updateShouldNotify(ThemeScope old) => theme.id != old.theme.id;
}

/// 便捷访问：`context.theme.bg`
extension ThemeContext on BuildContext {
  AppTheme get theme => ThemeScope.of(this);
}
