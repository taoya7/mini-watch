import 'package:flutter/foundation.dart';
import '../types/base_info.dart';

/// 主机基础信息 store（单例 ChangeNotifier）
/// 数据来自服务端 ws onOpen 时主动下发的 `base_info` 报文
class BaseInfoStore extends ChangeNotifier {
  BaseInfoStore._();
  static final instance = BaseInfoStore._();

  BaseInfo? _info;
  BaseInfo? get info => _info;

  void update(BaseInfo info) {
    _info = info;
    notifyListeners();
  }
}

BaseInfoStore get baseInfoStore => BaseInfoStore.instance;
