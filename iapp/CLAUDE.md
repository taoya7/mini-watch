# iapp

Flutter 应用项目。

## 平台

- 当前仅 iOS（`ios/`）；无 `android/` 目录，需要时用 `flutter create --platforms=android .` 生成。
- SDK：`^3.11.4`（见 `pubspec.yaml`）。

## 目录结构

```
lib/
├── main.dart       # 应用入口
├── pages/          # 页面（Scaffold 级别，一屏一文件）
├── components/     # 可复用 UI 组件
├── routes/         # 路由配置与守卫
├── store/          # 状态管理
├── utils/          # 工具函数（纯函数 / 扩展）
└── constants/      # 常量、枚举、主题色、字符串
```

## 依赖

- `mobile_scanner`: 扫码（iOS 已配 `NSCameraUsageDescription`）。

## 运行

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run                 # 自动选已开 iOS 模拟器
```

改原生权限/插件后需重跑 `flutter run`，热重载不生效。

## 约定

- 页面文件命名 `xxx_page.dart`，组件 `xxx.dart`，工具按功能拆文件。
- 改完代码不要主动起 dev / 装依赖，给命令让用户自己执行。
