# Codex 工作指引

本文件是本项目所有开发工作的入口。开始任务前先阅读本文件，并根据任务类型阅读对应标准。

## 标准文件索引

- 产品需求：`docs/01-product-requirements.md`
- 技术架构：`docs/02-technical-architecture.md`
- 设计规范：`docs/03-design-guidelines.md`
- 开发流程：`docs/04-development-workflow.md`
- 测试与验收：`docs/05-testing-and-acceptance.md`
- 开发日志说明：`dev-logs/README.md`
- 每日开发日志：`dev-logs/YYYY-MM-DD.md`

## 工作说明

1. 开始开发前确认需求和现有代码，不擅自扩大第一版范围。
2. 使用 SwiftUI、SwiftData 和 Apple 系统框架，避免无必要的第三方依赖。
3. 修改数据模型、公开接口或核心交互时，同步更新 `docs/` 中的对应标准。
4. 每次开发完成后运行构建与相关测试，不能验证的事项必须明确记录。
5. 当天结束前更新开发日志，区分已完成、验证结果、待办和风险；不得把计划写成已完成。
6. 保持界面为极简原生 macOS 风格，优先可读性、键盘操作和辅助功能。
7. 学习内容需准确、自然、适合日常交流；模板生成内容必须经过抽样检查。

## 当前交付目标

完成可在 macOS 14 及以上运行的离线英语学习助手，具备每日学习、发音、学习状态、历史记录、通知和设置功能。
