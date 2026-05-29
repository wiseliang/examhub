import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../models/exam_timeline.dart';
import '../theme/app_theme.dart';

class ExamDetailScreen extends StatefulWidget {
  final int examId;

  const ExamDetailScreen({super.key, required this.examId});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();

  Exam? _exam;
  List<ExamTimeline> _timelines = [];
  List<ExamNotice> _notices = [];
  bool _isFollowing = false;
  bool _isBookmarked = false;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final exam = await _db.getExamById(widget.examId);
      final timelines = await _db.getTimelines(widget.examId);
      final notices = await _db.getNotices(widget.examId);
      final isFollowing = await _db.isFollowing(widget.examId);
      final isBookmarked = await _db.isBookmarked(widget.examId);

      // 记录浏览历史
      await _db.recordBrowse(widget.examId);

      setState(() {
        _exam = exam;
        _timelines = timelines;
        _notices = notices;
        _isFollowing = isFollowing;
        _isBookmarked = isBookmarked;
        _loading = false;
      });
    } catch (e) {
      debugPrint('加载考试详情失败: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('考试详情')),
        body: const Center(child: Text('未找到该考试信息')),
      );
    }

    final exam = _exam!;
    final industryColor = AppTheme.getIndustryColor(exam.industry);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Colors.white,
              title: Text(exam.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  )),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        industryColor.withValues(alpha: 0.15),
                        industryColor.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(exam.fullName,
                              style: AppTheme.heading3),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStars(exam.goldContent),
                              const SizedBox(width: 8),
                              Text('${exam.goldContent} 含金量',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentColor,
                                  )),
                              const SizedBox(width: 16),
                              Icon(Icons.school,
                                  size: 14, color: AppTheme.textLight),
                              const SizedBox(width: 4),
                              Text('难度 ${exam.difficulty}/5',
                                  style: AppTheme.caption),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color:
                        _isBookmarked ? AppTheme.accentColor : Colors.white70,
                  ),
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () {
                    // TODO: 分享功能
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textLight,
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(text: '概览'),
                  Tab(text: '通知'),
                  Tab(text: '数据'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(exam),
            _buildNoticesTab(),
            _buildDataTab(exam),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(exam),
    );
  }

  // ==================== Tab: 概览 ====================

  Widget _buildOverviewTab(Exam exam) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // 标签行
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoTag(exam.category, AppTheme.getCategoryColor(exam.category)),
            _buildInfoTag(exam.industry, AppTheme.getIndustryColor(exam.industry)),
            ...exam.targetGroups
                .map((g) => _buildInfoTag(g, AppTheme.primaryColor)),
          ],
        ),

        const SizedBox(height: AppTheme.spacingLg),

        // 简介
        _buildSectionTitle('📋 考试简介'),
        const SizedBox(height: 8),
        Text(exam.description, style: AppTheme.body),
        const SizedBox(height: AppTheme.spacingLg),

        // 主办单位
        _buildSectionTitle('🏛️ 主办单位'),
        const SizedBox(height: 4),
        Text(exam.organizingBody, style: AppTheme.body),
        if (exam.officialWebsite.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('官网: ${exam.officialWebsite}',
              style: AppTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                decoration: TextDecoration.underline,
              )),
        ],

        const SizedBox(height: AppTheme.spacingLg),

        // 报名条件
        _buildSectionTitle('✅ 报名条件'),
        const SizedBox(height: 8),
        Text(exam.eligibility, style: AppTheme.body),

        const SizedBox(height: AppTheme.spacingLg),

        // 考试科目
        _buildSectionTitle('📝 考试科目'),
        const SizedBox(height: 8),
        if (exam.subjects.isNotEmpty)
          ...exam.subjects.map((subject) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      subject.format == '机考'
                          ? Icons.computer_rounded
                          : subject.format == '面试'
                              ? Icons.people_rounded
                              : Icons.edit_rounded,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(subject.name,
                        style: AppTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ))),
                    Text('${subject.duration}分钟',
                        style: AppTheme.caption),
                  ],
                ),
              )),

        const SizedBox(height: AppTheme.spacingLg),

        // 时间节点
        _buildSectionTitle('📅 考试时间节点'),
        const SizedBox(height: 8),
        if (_timelines.isNotEmpty)
          ..._timelines.map((tl) => _buildTimelineRow(tl)),

        if (_timelines.isEmpty)
          Text('暂无时间信息', style: AppTheme.caption),

        const SizedBox(height: 80),
      ],
    );
  }

  // ==================== Tab: 通知 ====================

  Widget _buildNoticesTab() {
    if (_notices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_rounded,
                size: 48, color: AppTheme.textLight),
            const SizedBox(height: 12),
            const Text('暂无官方通知',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('官方通知将在此显示',
                style: AppTheme.caption),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _notices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notice = _notices[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(notice.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${notice.publishDate.year}-${notice.publishDate.month.toString().padLeft(2, '0')}-${notice.publishDate.day.toString().padLeft(2, '0')}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
              if (notice.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(notice.summary, style: AppTheme.bodySmall,
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              if (notice.keyPoints.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: notice.keyPoints.map((kp) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor
                              .withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(kp.content,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.warningColor,
                            )),
                      )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ==================== Tab: 数据 ====================

  Widget _buildDataTab(Exam exam) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        _buildSectionTitle('📊 考试概览'),
        const SizedBox(height: 12),

        // 指标卡片行
        Row(
          children: [
            Expanded(
                child: _buildMetricCard(
                    '含金量', '${exam.goldContent}', '⭐', AppTheme.accentColor)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildMetricCard(
                    '难度', '${exam.difficulty}/5', '📊', AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildMetricCard('科目数',
                    '${exam.subjects.length}个', '📝', AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildMetricCard('考试形式',
                    exam.examFormat, '💻', AppTheme.successColor)),
          ],
        ),

        const SizedBox(height: AppTheme.spacingLg),
        _buildSectionTitle('🏷️ 分类信息'),
        const SizedBox(height: 8),
        _buildInfoRow('类型', exam.category),
        _buildInfoRow('行业', exam.industry),
        _buildInfoRow('适用人群', exam.targetGroups.join(' / ')),
        if (exam.tags.isNotEmpty)
          _buildInfoRow('标签', exam.tags.join(' · ')),

        const SizedBox(height: 80),
      ],
    );
  }

  // ==================== 底部操作栏 ====================

  Widget _buildBottomBar(Exam exam) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm + 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleBookmark,
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                ),
                label: Text(_isBookmarked ? '已收藏' : '收藏'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _toggleFollow,
                icon: Icon(
                  _isFollowing
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  size: 20,
                ),
                label: Text(_isFollowing ? '已关注' : '关注考试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 辅助方法 ====================

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star,
              size: 16, color: AppTheme.accentColor);
        }
        return const Icon(Icons.star_border,
            size: 16, color: AppTheme.textLight);
      }),
    );
  }

  Widget _buildInfoTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.heading3);
  }

  Widget _buildTimelineRow(ExamTimeline tl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(tl.eventIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tl.eventTypeLabel, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              )),
              Text(tl.periodDesc, style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          )),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: AppTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTheme.body)),
        ],
      ),
    );
  }

  Future<void> _toggleFollow() async {
    if (_exam == null) return;
    if (_isFollowing) {
      await _db.unfollowExam(_exam!.id);
      setState(() => _isFollowing = false);
    } else {
      await _db.followExam(_exam!.id);
      setState(() => _isFollowing = true);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_exam == null) return;
    if (_isBookmarked) {
      await _db.unbookmarkExam(_exam!.id);
      setState(() => _isBookmarked = false);
    } else {
      await _db.bookmarkExam(_exam!.id);
      setState(() => _isBookmarked = true);
    }
  }
}
