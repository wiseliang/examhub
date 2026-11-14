import 'package:material_ui/material_ui.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../widgets/exam_search_delegate.dart';
import 'custom_exam_screen.dart';
import 'discover_screen.dart';
import 'exam_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onBrowse;
  final bool active;
  const HomeScreen({super.key, this.onBrowse, this.active = true});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  List<Exam> _exams = [], _followed = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {super.initState(); _load();}
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {super.didUpdateWidget(oldWidget); if (widget.active && !oldWidget.active) _load();}
  Future<void> _load() async {
    try {
      final exams = await _db.getAllExams();
      final followed = await _db.getFollowedExams();
      if (mounted) setState(() {_exams = exams; _followed = followed; _loading = false; _error = null;});
    } catch (_) {if (mounted) setState(() {_loading = false; _error = '考试资料读取失败，请重试。';});}
  }
  Future<void> _detail(Exam exam) async {await Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDetailScreen(examId: exam.id))); if (mounted) await _load();}
  Future<void> _add() async {await openCustomExam(context); if (mounted) await _load();}
  void _browse() {if (widget.onBrowse != null) {widget.onBrowse!();} else {Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscoverScreen()));}}
  Future<void> _search() async {final exam = await showSearch<Exam?>(context: context, delegate: ExamSearchDelegate()); if (exam != null && mounted) await _detail(exam); else if (mounted) await _load();}
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
    Padding(padding: const EdgeInsets.fromLTRB(20, 18, 12, 0), child: Row(children: [const BrandMark(), const SizedBox(width: 10), const Text('考试通', style: AppTheme.heading3), const Spacer(), TextButton.icon(onPressed: _add, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('添加考试'))])),
    const PageHeading('你的下一场考试', '从了解考试，到开始准备。'),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12), child: InkWell(onTap: _search, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(border: Border.all(color: AppTheme.dividerColor), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.search_rounded, color: AppTheme.primaryColor), SizedBox(width: 12), Expanded(child: Text('搜索考试名称、行业', style: AppTheme.bodySmall))]))))),
    const SizedBox(height: 20),
    Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('我的备考', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (_followed.isEmpty) ...[
        const Text('先选一门想考的考试', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        const Text('关注后，考试资料和安排会集中在这里。', style: TextStyle(color: Color(0xFFDFE7FF), fontSize: 13, height: 1.6)),
        const SizedBox(height: 18),
        FilledButton(onPressed: _browse, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryColor), child: const Text('去选考试')),
      ] else ...[
        ..._followed.take(2).map((exam) => InkWell(onTap: () => _detail(exam), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(exam.name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(exam.targetDate == null ? '查看资料与考试安排' : '我的目标日 ${shortDate(exam.targetDate!)}', style: const TextStyle(color: Color(0xFFDFE7FF), fontSize: 13))])), const Icon(Icons.chevron_right_rounded, color: Colors.white)])))),
        if (_followed.length > 2) Text('另有 ${_followed.length - 2} 门考试，可在“我的”查看。', style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ])),
    SectionHeading('考试目录', action: '查看全部', onTap: _browse),
    if (_loading) const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())) else if (_error != null) EmptyPanel(title: '暂时没能读取资料', message: _error!, action: '重新读取', onTap: _load) else ..._exams.where((e) => !e.isCustom).take(6).map((exam) => Column(children: [ExamRow(exam: exam, onTap: () => _detail(exam)), const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider())])),
    const SizedBox(height: 24),
    EmptyPanel(title: '没有找到要考的？', message: '升学、招聘、技能考试，都可以加入自己的备考列表。', action: '添加自己的考试', onTap: _add, icon: Icons.post_add_rounded),
    const SizedBox(height: 28),
  ]))));
}
