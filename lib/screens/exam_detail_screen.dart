import 'package:material_ui/material_ui.dart';

import '../database/database_helper.dart';
import '../models/exam.dart';
import '../models/exam_session.dart';
import '../models/exam_timeline.dart';
import '../services/external_actions.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'custom_exam_screen.dart';
import 'assistant_screen.dart';

class ExamDetailScreen extends StatefulWidget {
  final int examId;
  const ExamDetailScreen({super.key, required this.examId});
  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  late final TabController _tabs;
  Exam? _exam;
  List<ExamSession> _sessions = [];
  List<ExamTimeline> _timelines = [];
  List<ExamNotice> _notices = [];
  int? _selectedSession;
  bool _following = false, _bookmarked = false, _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final exam = await _db.getExamById(widget.examId);
      final sessions = await _db.getSessions(widget.examId);
      final timelines = await _db.getTimelines(widget.examId);
      final notices = await _db.getNotices(widget.examId);
      final following = await _db.isFollowing(widget.examId),
          bookmarked = await _db.isBookmarked(widget.examId);
      if (exam != null) await _db.recordBrowse(widget.examId);
      if (mounted) {
        setState(() {
          _exam = exam;
          _sessions = sessions;
          _timelines = timelines;
          _notices = notices;
          _selectedSession = sessions.firstOrNull?.id;
          _following = following;
          _bookmarked = bookmarked;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '资料读取失败，请重试。';
        });
      }
    }
  }

  Future<void> _follow() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_following) {
        await _db.unfollowExam(widget.examId);
      } else {
        await _db.followExam(widget.examId);
      }
      if (mounted) setState(() => _following = !_following);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('关注状态未保存，请重试。')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bookmark() async {
    try {
      if (_bookmarked) {
        await _db.unbookmarkExam(widget.examId);
      } else {
        await _db.bookmarkExam(widget.examId);
      }
      if (mounted) setState(() => _bookmarked = !_bookmarked);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('收藏未保存，请重试。')));
      }
    }
  }

  Future<void> _manage(String action) async {
    final exam = _exam;
    if (exam == null || !exam.isCustom) return;
    if (action == 'edit') {
      await Navigator.push<int>(
        context,
        MaterialPageRoute(builder: (_) => CustomExamScreen(existing: exam)),
      );
      if (mounted) await _load();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这门个人考试？'),
        content: const Text('会同时移除本机的关注、收藏和浏览记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.deleteCustomExam(exam.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除未完成，请重试。')));
      }
    }
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.heading3),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final exam = _exam;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('考试档案')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (exam == null || _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('考试档案')),
        body: Center(
          child: EmptyPanel(
            title: '暂时无法显示考试',
            message: _error ?? '这份考试档案不存在。',
            action: '重新读取',
            onTap: _load,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('考试档案'),
        actions: [
          IconButton(
            tooltip: '让助手规划备考',
            icon: const Icon(Icons.travel_explore),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssistantScreen(initialExam: exam.fullName))),
          ),
          if (exam.isCustom)
            PopupMenuButton<String>(
              tooltip: '管理个人考试',
              onSelected: _manage,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑个人考试')),
                PopupMenuItem(value: 'delete', child: Text('删除个人考试')),
              ],
            ),
          IconButton(
            tooltip: _bookmarked ? '取消收藏' : '收藏考试',
            onPressed: _bookmark,
            icon: Icon(
              _bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatePill(exam.isCustom ? '个人添加' : exam.industry),
                    if (!exam.isCustom) const StatePill('资料待核验'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  exam.name,
                  style: AppTheme.heading1,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (exam.fullName != exam.name)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(exam.fullName, style: AppTheme.bodySmall),
                  ),
                if (exam.targetDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '我的目标日 ${shortDate(exam.targetDate!)}',
                      style: AppTheme.body,
                    ),
                  ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: '概览'),
              Tab(text: '考试安排'),
              Tab(text: '刷题准备'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_overview(exam), _schedule(exam), _practice(exam)],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _follow,
                  icon: Icon(
                    _following ? Icons.check_rounded : Icons.add_rounded,
                    size: 18,
                  ),
                  label: Text(_following ? '已关注' : '关注考试'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      ExternalActions.practice(context, exam: exam),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('开始刷题'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overview(Exam exam) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _section('了解这门考试', Text(exam.description, style: AppTheme.body)),
      _section('报考条件', Text(exam.eligibility, style: AppTheme.body)),
      if (exam.organizingBody.isNotEmpty)
        _section('组织机构', Text(exam.organizingBody, style: AppTheme.body)),
      if (exam.officialWebsite.isNotEmpty)
        _section(
          '信息来源',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(exam.officialWebsite, style: AppTheme.bodySmall),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    ExternalActions.open(context, exam.officialWebsite),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('查看来源网址'),
              ),
            ],
          ),
        ),
      _section(
        '考试科目',
        exam.subjects.isEmpty
            ? const Text(
                '科目资料待补充，可先在掌心刷题选择或导入自己的题库。',
                style: AppTheme.bodySmall,
              )
            : Column(
                children: exam.subjects
                    .map(
                      (subject) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(
                                Icons.description_outlined,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(subject.name, style: AppTheme.body),
                            ),
                            Text(
                              '${subject.duration} 分钟',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
      if (_notices.isNotEmpty)
        _section(
          '相关公告',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _notices
                .map(
                  (notice) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notice.title, style: AppTheme.heading3),
                        Text(
                          shortDate(notice.publishDate),
                          style: AppTheme.caption,
                        ),
                        if (notice.summary.isNotEmpty)
                          Text(notice.summary, style: AppTheme.body),
                        if (notice.sourceUrl.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                ExternalActions.open(context, notice.sourceUrl),
                            child: const Text('查看公告原文'),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      const Text('报考条件与安排可能调整，请核对当年、当地官方公告。', style: AppTheme.bodySmall),
    ],
  );
  Widget _schedule(Exam exam) {
    final selected = _sessions
        .where((s) => s.id == _selectedSession)
        .firstOrNull;
    final events = _timelines
        .where((e) => e.sessionId == _selectedSession)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (exam.targetDate != null)
          _section(
            '我的目标日期',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortDate(exam.targetDate!), style: AppTheme.heading2),
                const Text('这是你填写的备考目标，不作为官方考试日期。', style: AppTheme.bodySmall),
              ],
            ),
          ),
        if (_sessions.isEmpty)
          EmptyPanel(
            title: '安排尚待补充',
            message: '关注考试后，可以先收集官方资料，并在掌心刷题开始准备。',
            action: '查看刷题入口',
            onTap: () => _tabs.animateTo(2),
            icon: Icons.event_note_outlined,
          )
        else ...[
          DropdownButtonFormField<int>(
            initialValue: _selectedSession,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '年份 / 地区 / 批次'),
            items: _sessions
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      s.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) => setState(() => _selectedSession = id),
          ),
          const SizedBox(height: 20),
          if (selected != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: StatePill(
                selected.statusLabel,
                verified: selected.status == 'confirmed',
              ),
            ),
            const SizedBox(height: 10),
            Text(selected.statusDescription, style: AppTheme.bodySmall),
            if (selected.sourceUrl != null)
              TextButton(
                onPressed: () =>
                    ExternalActions.open(context, selected.sourceUrl!),
                child: const Text('查看安排来源'),
              ),
            if (selected.publishedAt != null)
              Text(
                '公告日期 ${shortDate(selected.publishedAt!)}',
                style: AppTheme.caption,
              ),
            if (selected.verifiedAt != null)
              Text(
                '核验日期 ${shortDate(selected.verifiedAt!)}',
                style: AppTheme.caption,
              ),
          ],
          const SizedBox(height: 24),
          ...events.map(
            (event) => Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.dividerColor),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.event_outlined,
                    color: AppTheme.primaryColor,
                    size: 21,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.eventTypeLabel, style: AppTheme.heading3),
                        const SizedBox(height: 5),
                        Text(event.periodDesc, style: AppTheme.body),
                        if (event.status == 'confirmed' && event.date != null)
                          Text(
                            shortDate(event.date!),
                            style: AppTheme.heading3,
                          ),
                        Text(
                          ExamSession.statuses[event.status] ?? '待核验',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (events.isEmpty)
            const Text('这个批次尚无具体日期。', style: AppTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _practice(Exam exam) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Icon(
        Icons.menu_book_rounded,
        color: AppTheme.primaryColor,
        size: 36,
      ),
      const SizedBox(height: 16),
      const Text('从考试资料，走到练习。', style: AppTheme.heading2),
      const SizedBox(height: 12),
      Text(
        '打开掌心刷题，选择“${exam.name}”对应的题库。没有合适的题库时，可以导入自己的题目或资料。',
        style: AppTheme.body,
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => ExternalActions.practice(context, exam: exam),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text('复制考试名称并打开掌心刷题'),
      ),
      const SizedBox(height: 14),
      const Text(
        '本次会复制考试名称。掌心刷题需使用自己的账号登录，并由你选择题库。',
        style: AppTheme.bodySmall,
      ),
      const SizedBox(height: 24),
      OutlinedButton(
        onPressed: () => ExternalActions.open(
          context,
          'https://wiseliang.cloud/palm-quiz/release/',
        ),
        child: const Text('下载掌心刷题 App'),
      ),
    ],
  );
}
