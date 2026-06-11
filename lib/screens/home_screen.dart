import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import '../widgets/exam_card.dart';
import '../widgets/exam_search_delegate.dart';
import 'exam_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  List<Exam> _hotExams = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  Set<int> _bookmarkedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final hotExams = await _db.getHotExams(limit: 30);
      final events = await _db.getUpcomingEvents(days: 60);

      // 加载收藏状态
      final bookmarked = <int>{};
      for (final exam in hotExams) {
        if (await _db.isBookmarked(exam.id)) {
          bookmarked.add(exam.id);
        }
      }

      setState(() {
        _hotExams = hotExams;
        _upcomingEvents = events;
        _bookmarkedIds = bookmarked;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('加载首页数据失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('考试通'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: () {
              // TODO: 打开考试日历
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _onSearch(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  // 考试日历横向滑动
                  if (_upcomingEvents.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildUpcomingEvents(),
                    ),

                  // Section标题
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppTheme.spacingMd, AppTheme.spacingMd,
                          AppTheme.spacingMd, AppTheme.spacingSm),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up_rounded,
                              size: 20, color: AppTheme.accentColor),
                          SizedBox(width: 6),
                          Text('热门考试',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              )),
                        ],
                      ),
                    ),
                  ),

                  // 考试卡片Feed流
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final exam = _hotExams[index];
                        return ExamCard(
                          exam: exam,
                          isBookmarked: _bookmarkedIds.contains(exam.id),
                          onTap: () => _navigateToDetail(context, exam),
                          onBookmark: () => _toggleBookmark(exam),
                        );
                      },
                      childCount: _hotExams.length,
                    ),
                  ),

                  // 底部留白
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
    );
  }

  /// 近期考试事件横向滚动
  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppTheme.spacingMd, AppTheme.spacingLg,
              AppTheme.spacingMd, AppTheme.spacingSm),
          child: Row(
            children: [
              Icon(Icons.event_rounded,
                  size: 18, color: AppTheme.warningColor),
              SizedBox(width: 6),
              Text('近期节点',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  )),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd),
            itemCount: _upcomingEvents.length.clamp(0, 10),
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spacingSm),
            itemBuilder: (context, index) {
              final event = _upcomingEvents[index];
              return _buildEventCard(event);
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventType = event['event_type'] as String? ?? '';
    final examName = event['exam_name'] as String? ?? '';
    final periodDesc = event['period_desc'] as String? ?? '';

    final iconMap = {
      'signup_start': '📝',
      'signup_end': '⏰',
      'admit_card': '🎫',
      'exam': '📖',
      'score': '📊',
    };

    return GestureDetector(
      onTap: () {
        final examId = event['exam_id'] as int?;
        if (examId != null) {
          _navigateToDetailById(context, examId);
        }
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(iconMap[eventType] ?? '📌', style: const TextStyle(fontSize: 20)),
            const Spacer(),
            Text(examName,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(periodDesc,
                style: AppTheme.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  /// 搜索
  Future<void> _onSearch(BuildContext context) async {
    final result = await showSearch<Exam?>(
      context: context,
      delegate: ExamSearchDelegate(),
    );
    if (result != null && mounted) {
      _navigateToDetail(context, result);
    }
  }

  /// 导航到考试详情
  void _navigateToDetail(BuildContext context, Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamDetailScreen(examId: exam.id),
      ),
    ).then((_) => _loadData()); // 返回时刷新（可能改变了收藏/关注状态）
  }

  void _navigateToDetailById(BuildContext context, int examId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamDetailScreen(examId: examId),
      ),
    ).then((_) => _loadData());
  }

  /// 切换收藏状态
  Future<void> _toggleBookmark(Exam exam) async {
    final isBookmarked = _bookmarkedIds.contains(exam.id);
    if (isBookmarked) {
      await _db.unbookmarkExam(exam.id);
      setState(() => _bookmarkedIds.remove(exam.id));
    } else {
      await _db.bookmarkExam(exam.id);
      setState(() => _bookmarkedIds.add(exam.id));
    }
  }
}
