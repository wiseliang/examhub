# GitHub 自动构建流程

已确认继续 Flutter Android App，将检查、测试、打包交给 GitHub 托管 runner；不在项目服务器运行 Gradle、Android SDK 下载或后台构建服务。

## 触发方式

- 向 `master` 或 `codex/**` 开发分支推送代码：检查、测试并生成 Android ARM64 Release 优化测试 APK。
- Pull Request：运行格式、静态分析、业务与数据库迁移测试，不重复打包。
- 仓库 Actions → Flutter checks and Android APK → Run workflow：手动构建。手动入口需要该工作流存在于默认分支；合并前由开发分支推送触发构建。
- 仅修改 Markdown 文档不自动构建；同分支新提交会取消旧构建。

## 安装包下载

在成功运行页面底部的 Artifacts 下载 `examhub-android-release-运行编号`，其中包含：

- `考试通安卓精简版.apk`
- `安装包校验.txt`（SHA-256）
- `构建信息.txt`（提交与运行编号）

产物保留 7 天，不自动发布 Release、不部署服务器、不上传商店。此包使用 Release 优化和调试签名，不是正式签名包，不保证跨构建覆盖安装；后续正式试用版本应使用 GitHub Secrets 中的固定签名。

## 资源与权限

- 使用 `ubuntu-latest` 托管 runner，不注册项目服务器为 self-hosted runner。
- 单次最多 35 分钟，没有定时轮询或常驻服务。
- 仓库 token 仅授予 `contents: read`。
- 固定 Flutter 3.50.0、Java 21 和依赖锁文件；复用 Flutter 下载缓存。
- 成功构建不等于真机启动、通知或升级验收，设备测试单独记录。

## 项目开发顺序

下一批继续在线数据更新与核验发布接口，基础仍按《开发流程与里程碑.md》推进。本轮已完成的年度/地区/批次模型、兼容迁移与 12 项测试一并纳入云端验证。

本约定先用于 examhub；其他项目迁移时分别检查其已有构建、签名和发布方式，不直接修改生产服务。

## 体积优化

采用 ARM64 单架构、Release AOT、图标裁剪、R8 代码及资源裁剪，并将 Dart 调试信息分离保存到独立的 symbols 产物；默认下载的 APK 不包含这些调试符号。不对已签名 APK 做二次 ZIP 改写。
