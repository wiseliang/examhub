import 'package:material_ui/material_ui.dart';

import '../database/database_helper.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'custom_exam_screen.dart';
import 'exam_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _search = TextEditingController();
  List<Exam> _all = [];
  String? _industry, _category, _targetGroup;
  bool _customOnly = false, _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final exams = await DatabaseHelper().getAllExams();
      if (mounted) {
        setState(() {
          _all = exams;
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

  Future<void> _add() async {
    await openCustomExam(context, initialName: _search.text.trim());
    if (mounted) await _load();
  }

  List<Exam> get _results {
    final query = _search.text.trim().toLowerCase();
    return _all
        .where(
          (e) =>
              (_industry == null || e.industry == _industry) &&
              (_category == null || e.category == _category) &&
              (_targetGroup == null || e.targetGroups.contains(_targetGroup)) &&
              (!_customOnly || e.isCustom) &&
              (query.isEmpty ||
                  [
                    e.name,
                    e.fullName,
                    e.industry,
                    e.organizingBody,
                    e.description,
                  ].any((s) => s.toLowerCase().contains(query))),
        )
        .toList();
  }

  Future<void> _filters() async {
    final categories = _all.map((e) => e.category).toSet().toList()..sort();
    final groups = _all.expand((e) => e.targetGroups).toSet().toList()..sort();
    String category = _category ?? '', group = _targetGroup ?? '';
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('筛选考试', style: AppTheme.heading2),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: '考试类型'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('全部类型')),
                    ...categories.map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    ),
                  ],
                  onChanged: (value) => update(() => category = value ?? ''),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: group,
                  decoration: const InputDecoration(labelText: '适用人群'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('全部人群')),
                    ...groups.map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    ),
                  ],
                  onChanged: (value) => update(() => group = value ?? ''),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context, (category, group)),
                  child: const Text('应用筛选'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, ('', '')),
                  child: const Text('清除筛选'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _category = result.$1.isEmpty ? null : result.$1;
        _targetGroup = result.$2.isEmpty ? null : result.$2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final industries = _all.map((e) => e.industry).toSet().toList()..sort();
    final results = _results;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeading(
              '考试库',
              '找到适合自己的方向。',
              trailing: IconButton(
                tooltip: '添加考试',
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索考试名称、行业',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清除搜索',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _industry == null,
                    onSelected: (_) => setState(() => _industry = null),
                  ),
                  const SizedBox(width: 8),
                  ...industries.map(
                    (industry) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(industry),
                        selected: _industry == industry,
                        onSelected: (_) => setState(
                          () => _industry = _industry == industry
                              ? null
                              : industry,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
              child: Row(
                children: [
                  Expanded(child: Text('找到 ${results.length} 门考试', style: AppTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  TextButton.icon(
                    onPressed: _filters,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: Text(
                      _category != null || _targetGroup != null ? '已筛选' : '筛选',
                    ),
                  ),
                  FilterChip(
                    label: const Text('我添加的'),
                    selected: _customOnly,
                    onSelected: (value) => setState(() => _customOnly = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (_error != null)
                            EmptyPanel(
                              title: '暂时无法显示考试',
                              message: _error!,
                              action: '重新读取',
                              onTap: _load,
                            )
                          else if (results.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: EmptyPanel(
                                title: _search.text.isEmpty
                                    ? '这个范围还没有考试'
                                    : '没有找到“${_search.text.trim()}”',
                                message: '可以调整筛选，也可以自己添加，先开始准备。',
                                action: '添加这个考试',
                                onTap: _add,
                                icon: Icons.search_off_rounded,
                              ),
                            )
                          else
                            ...results.map(
                              (exam) => Column(
                                children: [
                                  ExamRow(
                                    exam: exam,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ExamDetailScreen(examId: exam.id),
                                        ),
                                      );
                                      if (mounted) await _load();
                                    },
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Divider(),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          if (results.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: OutlinedButton.icon(
                                onPressed: _add,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('目录里没有？添加自己的考试'),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
