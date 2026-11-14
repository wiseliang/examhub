> 2026-11-14 新增 1.3 备考助手测试版：真实联网研究、题库候选、学习日与时间预算排程、离线打卡及未完成任务重排。联网功能需连接轻量服务，尚未部署正式地址；详见 [主动备考助手设计与接入](docs/design/主动备考助手设计与接入.md)。

# 考试通 ExamHub

面向应届毕业生和职场人群的考试资料与个人备考工具。Flutter Android 客户端，当前版本 1.3.0+5。

## 已实现

- 备考首页、可搜索和筛选的考试库、考试档案、个人考试列表。
- 内置 40 个考试档案；按年度、地区、级别和批次区分安排。
- 未收录考试可自行添加，支持修改、删除、个人目标日期和自动关注。
- 本地关注、收藏及浏览历史；SQLite v1/v2 → v3 增量迁移保留个人数据。
- 掌心刷题 App / 网页入口、考试名称复制及 App 下载入口。

公共目录资料尚需核验；预计时间和个人目标不作为官方确定日期。个人考试保存在本机。掌心刷题题库、登录与学习进度没有自动互通，详细边界见 [联动方案](docs/design/掌心刷题联动方案.md)。

## 页面设计

使用蓝白色的备考工作台布局，突出搜索、个人备考和资料阅读，移除预设评分展示及虚构热度。页面结构和设计复核见 [设计说明](docs/design/页面重设计与考试扩展.md)。

CI 通过独立演示数据生成真实 Flutter 页面渲染预览，不使用私人题库或账户。中文字体仅下载到 CI 测试目录，不打进 APK。

## GitHub 自动构建

代码推送至 `master` 或 `codex/**` 后，GitHub 托管 runner 自动执行格式检查、静态分析、业务/迁移/页面测试及 ARM64 Release 优化 APK 构建。项目服务器无需 Flutter、Android SDK 或常驻构建服务。

成功运行的 Artifacts：

- `examhub-android-release-*`：优化 APK、校验值和构建信息，保留 7 天。
- `examhub-ui-*`：真实页面渲染预览，保留 7 天。
- `examhub-dart-symbols-*`：分离的 Dart 调试信息，保留 7 天。

PR 只检查测试，文档变更跳过自动运行。固定正式签名、真实 Android 设备启动和覆盖升级仍需后续验收。参见 [自动构建流程](docs/GitHub自动构建流程.md)。

## 本地开发（可选）

Flutter 3.50.0 / Dart 3.14.0，依赖由 `pubspec.lock` 固定。

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run
```

实际 Android 浏览器跳转通过本项目的平台通道实现；非 Android 平台提供复制网址的回退提示。Windows 工程仍需单独验证。

## 后续开发

核验首批重点考试并实现版本化信息更新，再接完整日历、系统提醒及经授权的深度刷题联动。原始长期愿景见 [产品设计](docs/设计文档.txt)，迭代顺序见 [开发流程](docs/开发流程与里程碑.md)。
