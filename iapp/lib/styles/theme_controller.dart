import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'themes.dart';

/// 全局主题控制器（单例 + ChangeNotifier + 持久化）
/// 切换主题后 `notifyListeners()` + 写入 SharedPreferences，下次启动自动恢复
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final instance = ThemeController._();

  static const _prefsKey = 'app_theme_id';

  AppTheme _current = themeAmber;
  AppTheme get current => _current;

  /// 应用启动时调用一次，从存储恢复上次选择
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefsKey);
    if (id == null) return;
    final saved = appThemes.firstWhere(
      (e) => e.id == id,
      orElse: () => themeAmber,
    );
    if (saved.id != _current.id) {
      _current = saved;
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_current.id == theme.id) return;
    _current = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, theme.id);
  }

  Future<void> setById(String id) async {
    final t = appThemes.firstWhere(
      (e) => e.id == id,
      orElse: () => themeAmber,
    );
    await setTheme(t);
  }
}

/// 便捷访问
ThemeController get themeController => ThemeController.instance;
