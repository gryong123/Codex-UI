# 英语学习助手

一个使用 SwiftUI 构建的离线 macOS 菜单栏英语学习应用，支持每日单词、相关短语、语法、系统发音、学习记录和每日通知。

## 运行

1. 使用 Xcode 16.2 或更高版本打开 `EnglishLearningAssistant.xcodeproj`。
2. 选择 `EnglishLearningAssistant` scheme。
3. 点击运行按钮。

应用最低支持 macOS 14。启动后不会占用 Dock，点击 macOS 顶部菜单栏的书本图标即可展开学习面板。首次打开面板会请求通知权限，默认每天上午 9:30 提醒。

## 命令行验证

```bash
swift test
xcodebuild \
  -project EnglishLearningAssistant.xcodeproj \
  -scheme EnglishLearningAssistant \
  -configuration Debug \
  -derivedDataPath .build/xcode \
  CODE_SIGNING_ALLOWED=NO \
  build
```

`swift run` 仅用于代码调试，不具备完整的 macOS 应用包环境；正常使用请通过 Xcode 工程运行。
