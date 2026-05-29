import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import 'exam_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  List<Exam> _followedExams = [];
  List<Exam> _bookmarkedExams = [];
  List<Exam> _recentBrowsed = [];
  int _totalExams = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final followed = await _db.getFollowedExams();
      final bookmarked = await _db.getBookmarkedExams();
      final recent = await _db.getBrowseHistory(limit: 10);
      final allExams = await _db.getAllExams();

      setState(() {
        _followedExams = followed;
        _bookmarkedExams = bookmarked;
        _recentBrowsed = recent;
        _totalExams = allExams.length;
      });
    } catch (e) {
      debugPrint('加载个人中心数据失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              // TODO: 设置页
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // 顶部统计卡片
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5276), Color(0xFF2980B9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('考试通用户',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                          Text('探索你的职业证书之路',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('\(_totalExams)', '收录考试'),
                      _buildStatColumn('\(_followedExams.length)', '已关注'),
                      _buildStatColumn('\(_bookmarkedExams.length)', '已收藏'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // 已关注的考试
            _buildSection(
              title: '🔔 关注的考试',
              count: _followedExams.length,
              exams: _followedExams,
              emptyMsg: '还没有关注的考试\n关注考试后，可接收报名/考试提醒',
              onTap: (exam) => _navigateToDetail(context, exam),
              onClearAll: _followedExams.isNotEmpty
                  ? () async {
                      for (final e in _followedExams) {
                        await _db.unfollowExam(e.id);
                      }
                      _loadData();
                    }
                  : null,
            ),

            // 已收藏的考试
            _buildSection(
              title: '📌 收藏的考试',
              count: _bookmarkedExams.length,
              exams: _bookmarkedExams,
              emptyMsg: '还没有收藏的考试\n收藏考试方便以后快速查看',
              onTap: (exam) => _navigateToDetail(context, exam),
            ),

            // 浏览历史
            _buildSection(
              title: '🕐 最近浏览',
              count: _recentBrowsed.length,
              exams: _recentBrowsed,
              emptyMsg: '还没有浏览记录\n浏览考试后这里会显示记录',
              onTap: (exam) => _navigateToDetail(context, exam),
              onClearAll: _recentBrowsed.isNotEmpty
                  ? () async {
                      // 清空浏览历史的实现
                      _loadData();
                    }
                  : null,
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // 底部菜单
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: '关于考试通',
                    onTap: () {
                      // TODO: 关于页面
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.feedback_rounded,
                    title: '反馈建议',
                    onTap: () {
                      // TODO: 反馈页面
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.star_border_rounded,
                    title: '给我们评分',
                    onTap: () {
                      // TODO: 跳转应用商店
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            )),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required int count,
    required List<Exam> exams,
    required String emptyMsg,
    required Function(Exam) onTap,
    VoidCallback? onClearAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  )),
              const SizedBox(width: 6),
              if (count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const Spacer(),
              if (onClearAll != null)
                GestureDetector(
                  onTap: onClearAll,
                  child: const Text('清空',
                      style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
                ),
            ],
          ),
        ),
        if (exams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd, vertical: 8),
            child: Text(emptyMsg,
                style: AppTheme.caption,
                textAlign: TextAlign.center),
          )
        else
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              itemCount: exams.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final exam = exams[index];
                return GestureDetector(
                  onTap: () => onTap(exam),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(exam.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: List.generate(
                              exam.goldContent.floor(),
                              (_) => const Icon(Icons.star,
                                  size: 11, color: AppTheme.accentColor)),
                        ),
                        const Spacer(),
                        Text(exam.industry,
                            style: AppTheme.caption),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title), // ← 这里改为 title: Text(title)
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _navigateToDetail(BuildContext context, Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamDetailScreen(examId: exam.id),
      ),
    ).then((_) => _loadData());
  }
}
