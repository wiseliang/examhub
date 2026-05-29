# ExamHub - 资格考试信息平台

## 项目概述

一款移动端 App，聚合中国所有资格考试和认可度高的证书考试信息。
核心定位：信息聚合 + 社区（社区 Phase 3 再做）。类似"资格考试领域的小红书+知乎"。

## 技术栈

- **前端**: Flutter 3.x (Dart)
- **后端**: Python FastAPI (Phase 2)
- **数据库**: SQLite (本地, Phase 1) → PostgreSQL (云端, Phase 2)
- **AI**: Claude API (公告解析, Phase 2)

## 项目结构

```
examhub/
├── lib/
│   ├── main.dart              # 入口
│   ├── app.dart               # App壳 + 底部Tab(首页/发现/我的)
│   ├── models/
│   │   ├── exam.dart          # 考试核心模型 (Exam, ExamSubject)
│   │   └── exam_timeline.dart # 时间节点模型 (ExamTimeline, ExamNotice, NoticeKeyPoint)
│   ├── database/
│   │   ├── database_helper.dart  # SQLite CRUD操作 (单例, 懒加载)
│   │   └── seed_data.dart        # 从assets/seed_exams.json加载种子数据
│   ├── theme/
│   │   └── app_theme.dart     # 主题配置 (配色/字体/间距/阴影/暗黑模式)
│   ├── widgets/
│   │   ├── exam_card.dart           # 考试卡片组件 (ExamCard, ExamCardCompact)
│   │   ├── category_selector.dart   # 横向滚动分类选择器 (CategorySelector, TagGroup)
│   │   └── exam_search_delegate.dart # 搜索代理 (ExamSearchDelegate)
│   └── screens/
│       ├── home_screen.dart         # 首页: Feed流 + 近期事件横向滚动
│       ├── discover_screen.dart     # 发现页: 多维筛选(行业×类别×人群) + 排序
│       ├── exam_detail_screen.dart  # 考试详情: 3个Tab(概览/通知/数据) + 底部操作栏
│       └── profile_screen.dart      # 个人中心: 关注/收藏/浏览历史
├── assets/
│   └── seed_exams.json        # 40个考试完整数据 (Python脚本生成)
├── scripts/
│   └── generate_seed_data.py  # 种子数据生成器
├── pubspec.yaml
└── [产品设计文档]../app设计5.30.txt
```

## 数据流

1. App启动 → DatabaseHelper._initDatabase() → 创建表 → SeedData.insertAll()
2. SeedData 从 assets/seed_exams.json 读取40个考试 → 写入 SQLite
3. 所有页面的数据都通过 DatabaseHelper 单例查询
4. Phase 1 零后端，所有数据本地存储

## 40个考试覆盖

| 行业 | 数量 | 代表 |
|------|------|------|
| 财会金融 | 10 | CPA/税务师/中级会计/初级会计/CFA/FRM/ACCA/证券/基金/资产评估师 |
| 建筑地产 | 8 | 一建/二建/注册建筑师/结构工程师/监理/造价/消防/房地产估价师 |
| 医疗健康 | 5 | 执业医师/执业药师/护士/执业兽医/健康管理师 |
| IT互联网 | 5 | 软考/华为认证/阿里云认证/AWS/CISSP |
| 法律 | 4 | 法考/专利代理人/企业合规师/LEC |
| 教育培训 | 4 | 教师资格证/普通话/国际中文教师/心理咨询师 |
| 公共管理 | 4 | 人力管理师/社会工作者/PMP/CATTI |

## 分阶段计划

**Phase 1 (当前)**: 4-6周 → 本地信息工具 MVP
- SQLite本地存储
- 40个考试数据嵌入
- 搜索/筛选/浏览/详情/关注/收藏/浏览历史
- 零后端、零用户系统

**Phase 2**: +4-6周 → 后端+自动化
- Python FastAPI + PostgreSQL
- 用户注册登录、云端同步
- 定时爬虫(10个重点考试)
- AI公告解析(Claude API)
- 推送通知

**Phase 3**: +6-8周 → 社区+生态
- 考试评价系统
- 经验分享/问答/圈子/打卡
- 个性化推荐
- 考试覆盖100+

## 关键设计决策

- UI风格: 内容丰富型(小红书+知乎), 卡片化, 大图引导, 标签系统
- 主色: 深蓝 #1A5276, 强调色: 暖橙金 #F39C12
- 底部3个Tab: 首页(Feed流) / 发现(筛选浏览) / 我的
- 分类体系: 5维度(管理属性/行业/人群/时间/社区指标)
- 社区Phase 3才做, 先验证信息工具价值

## 项目状态

- Flutter SDK: 已克隆到 D:\flutter
- Dart SDK: v3.12.0, 已下载
- pub get: 需要走代理(127.0.0.1:7892)才能完成
- 所有代码文件已编写完成
- 种子数据 JSON 已生成
- 待 pub get 完成后即可 flutter run

## 开发者环境

- 代理: http://127.0.0.1:7892 (Clash/V2Ray)
- Flutter PATH: D:\flutter\bin
- 代理需在 PowerShell 中设置: $env:http_proxy="http://127.0.0.1:7892"
