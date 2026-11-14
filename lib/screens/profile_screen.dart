import 'package:material_ui/material_ui.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../services/external_actions.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'custom_exam_screen.dart';
import 'exam_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool active;
  const ProfileScreen({super.key, this.active = true});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DatabaseHelper();
  List<Exam> _followed = [], _bookmarked = [], _history = [], _custom = [];
  String _selected = '关注';
  bool _loading = true;
  String? _error;
  @override
  void initState() {super.initState(); _load();}
  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {super.didUpdateWidget(oldWidget); if (widget.active && !oldWidget.active) _load();}
  Future<void> _load() async {
    try {final followed = await _db.getFollowedExams(), bookmarked = await _db.getBookmarkedExams(), history = await _db.getBrowseHistory(), all = await _db.getAllExams(); if (mounted) setState(() {_followed = followed; _bookmarked = bookmarked; _history = history; _custom = all.where((e) => e.isCustom).toList(); _loading = false; _error = null;});}
    catch (_) {if (mounted) setState(() {_loading = false; _error = '个人考试读取失败，请重试。';});}
  }
  Future<void> _add() async {await openCustomExam(context); if (mounted) await _load();}
  Future<void> _detail(Exam exam) async {await Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDetailScreen(examId: exam.id))); if (mounted) await _load();}
  @override
  Widget build(BuildContext context) {
    final lists = {'关注': _followed, '个人添加': _custom, '收藏': _bookmarked, '最近浏览': _history};
    final exams = lists[_selected]!;
    return Scaffold(body: SafeArea(child: RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
      const PageHeading('我的', '备考资料，都在这里。'),
      Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.dividerColor)), child: Row(children: [const BrandMark(), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('我的考试档案', style: AppTheme.heading3), SizedBox(height: 5), Text('关注、收藏和个人添加', style: AppTheme.bodySmall)])), IconButton(tooltip: '添加考试', onPressed: _add, icon: const Icon(Icons.add_rounded, color: AppTheme.primaryColor))])),
      const SizedBox(height: 20),
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: lists.entries.map((entry) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text('${entry.key} ${entry.value.length}'), selected: _selected == entry.key, onSelected: (_) => setState(() => _selected = entry.key)))).toList())),
      SectionHeading(_selected == '关注' ? '关注的考试' : _selected, action: _selected == '最近浏览' && exams.isNotEmpty ? '清空' : null, onTap: () async {await _db.clearBrowseHistory(); if (mounted) await _load();}),
      if (_loading) const Center(child: CircularProgressIndicator()) else if (_error != null) EmptyPanel(title: '暂时无法显示资料', message: _error!, action: '重新读取', onTap: _load)
      else if (exams.isEmpty) EmptyPanel(title: _selected == '个人添加' ? '考试不在目录里？' : '这里还没有考试', message: _selected == '最近浏览' ? '浏览过的考试会保存在这里。' : '可以在考试库关注，也可以添加自己的考试。', action: '添加自己的考试', onTap: _add)
      else ...exams.map((exam) => Column(children: [ExamRow(exam: exam, onTap: () => _detail(exam)), const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider())])),
      const SizedBox(height: 24),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(14), child: Column(children: [ListTile(leading: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor), title: const Text('掌心刷题'), subtitle: const Text('选择题库，开始练习'), trailing: const Icon(Icons.open_in_new_rounded, size: 18), onTap: () => ExternalActions.practice(context)), const Divider(indent: 56), ListTile(leading: const Icon(Icons.info_outline_rounded), title: const Text('关于考试通'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => showAboutDialog(context: context, applicationName: '考试通', applicationVersion: '1.2.0', children: const [Text('考试目录与个人备考工具。公共资料仍需核验，个人添加的内容仅保存在本机。')]))]))),
      const SizedBox(height: 28),
    ]))));
  }
}
