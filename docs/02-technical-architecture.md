# 技术架构

## 技术基线

- Swift 6
- SwiftUI
- SwiftData
- macOS 14+
- `AVSpeechSynthesizer` 离线语音
- `UNUserNotificationCenter` 系统通知
- Swift Package Manager 管理工程和测试
- `MenuBarExtra` 提供 macOS 顶部菜单栏入口

## 应用形态

- 主入口使用 `MenuBarExtra` 的 window 样式，点击菜单栏图标展开 900×620 点学习面板。
- 应用配置 `LSUIElement` 并使用 accessory activation policy，不在 Dock 中显示。
- 学习、历史和设置继续复用同一个 SwiftData 容器。
- 面板侧边栏提供明确的退出应用入口。

## 分层职责

- `Models.swift`：内容结构、SwiftData 持久化模型和状态枚举。
- `ContentRepository.swift`：内置日常生活场景词汇与语法、稳定 ID、内容解析和查询。
- `Services.swift`：发音、通知、每日抽取和学习状态写入。
- `Views/`：导航、今日学习、历史、设置及复用组件。

## 数据约束

- 内容 ID 全局稳定，发布后不得复用给不同内容。
- 内容正文可迭代更新，但现有词汇与短语 ID 应保持稳定，避免学习记录失联。
- `DailyStudyItem` 只保存日期、内容 ID、类型和顺序，不复制内容正文。
- `LearningProgress` 每个内容 ID 只允许一条当前状态。
- 每次状态变化都写入 `LearningActionEvent`，用于保留历史。
- 日期以用户当前系统时区的自然日为准。

## 错误处理

- 数据库初始化失败时记录明确错误，不静默丢失学习记录。
- 指定英文语音不存在时使用系统可用的英语语音。
- 通知被拒绝时保留其他功能，并在设置页提供系统设置入口。
- 内容 ID 无法解析时跳过该卡片，不导致整个页面崩溃。
