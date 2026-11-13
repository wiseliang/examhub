# 考试通 ExamHub

面向应届毕业生和职场人群的考试信息工具。使用 Flutter，当前有 Android 与 Windows 平台工程；本阶段优先验证 Android。

## 当前可用代码

- 内置 40 个考试档案，SQLite 本地存储。
- 名称及关键词搜索、行业/类别/人群筛选。
- 考试详情、科目、时间节点、本地关注、收藏和浏览历史。

数据是原型种子数据，尚未完成官方核验；考试条件与时间应核对官方公告。评分是预设值，非社区统计。在线更新、自动提醒、完整日历和社区尚未实现，部分入口仍为占位。

## 开发

Flutter 3.50.0 / Dart 3.14.0。依赖版本由 `pubspec.lock` 锁定。

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run
```

Android 构建需要 Android SDK 与 JDK。Windows 工程仍需在 Windows 设备验证，不因目录存在而视为已支持发布。

```sh
flutter build apk --debug
```

业务测试使用临时 SQLite，覆盖数据导入、搜索筛选、关注收藏、历史、日期边界和页面操作。CI 执行格式、静态分析、测试及 Android 调试构建。

## 开发文档

- [开发流程与里程碑](docs/开发流程与里程碑.md)
- [本轮开发记录](docs/开发记录_2026-11-14.md)
- [原始产品设计](docs/设计文档.txt)

原设计与旧会话总结描述了长期愿景，实际完成情况以当前代码、开发记录和验证结果为准。
