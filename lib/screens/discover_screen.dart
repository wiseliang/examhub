import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import '../widgets/category_selector.dart';
import '../widgets/exam_card.dart';
import '../widgets/exam_search_delegate.dart';
import 'exam_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();

  // 筛选状态
  String? _selectedCategory;
  String? _selectedIndustry;
  Set<String> _selectedTargetGroups = {};
  String _sortBy = '含金量'; // 含金量/难度/热度

  // 数据
  List<Exam> _exams = [];
  Map<String, int> _industryCounts = {};
  bool _loading = true;
  bool _showFilterPanel = false;

  // 分类常量
  final List<String> _categories = [
    '全部',
    '准入类',
    '水平评价类',
    '国际认证',
    '企业认证',
    '技能等级认定',
  ];

  final List<String> _industries = [
    '全部',
    '财会金融',
    '法律',
    '建筑地产',
    '医疗健康',
    '教育培训',
    'IT互联网',
    '公共管理',
  ];

  final List<String> _targetGroups = [
    '在校生',
    '应届',
    '职场1-3年',
    '职场3-5年+',
  ];

  final List<String> _sortOptions = ['含金量', '难度', '名称'];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _loading = true);
    try {
      final results = await _db.filterExams(
        category:
            _selectedCategory == '全部' ? null : _selectedCategory,
        industry:
            _selectedIndustry == '全部' ? null : _selectedIndustry,
        targetGroup: _selectedTargetGroups.isNotEmpty
            ? _selectedTargetGroups.first
            : null,
      );

      // 排序
      switch (_sortBy) {
        case '含金量':
          results.sort((a, b) => b.goldContent.compareTo(a.goldContent));
          break;
        case '难度':
          results.sort((a, b) => b.difficulty.compareTo(a.difficulty));
          break;
        case '名称':
          results.sort((a, b) => a.name.compareTo(b.name));
          break;
      }

      // 行业统计
      final counts = await _db.getExamCountByIndustry();

      setState(() {
        _exams = results;
        _industryCounts = counts;
        _loading = false;
      });
    } catch (e) {
      debugPrint('加载发现页数据失败: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilterPanel
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
            onPressed: () =>
                setState(() => _showFilterPanel = !_showFilterPanel),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _onSearch(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 行业分类选择器
          CategorySelector(
            items: _industries,
            selectedItem: _selectedIndustry ?? '全部',
            onSelected: (industry) {
              setState(() =>
                  _selectedIndustry = industry == '全部' ? null : industry);
              _loadExams();
            },
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // 类别选择器
          CategorySelector(
            items: _categories,
            selectedItem: _selectedCategory ?? '全部',
            onSelected: (category) {
              setState(() =>
                  _selectedCategory = category == '全部' ? null : category);
              _loadExams();
            },
          ),

          // 展开的筛选面板
          if (_showFilterPanel) _buildFilterPanel(),

          // 结果统计 + 排序
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd, AppTheme.spacingSm,
              AppTheme.spacingMd, AppTheme.spacingSm,
            ),
            child: Row(
              children: [
                Text('共 ${_exams.length} 个考试',
                    style: AppTheme.bodySmall),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    style: AppTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor),
                    items: _sortOptions
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('按$s排序'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                        _loadExams();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // 考试列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _exams.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadExams,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _exams.length,
                          itemBuilder: (context, index) {
                            final exam = _exams[index];
                            return ExamCard(
                              exam: exam,
                              onTap: () => _navigateToDetail(context, exam),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('适用人群', style: AppTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _targetGroups.map((group) {
              final isSelected = _selectedTargetGroups.contains(group);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTargetGroups.remove(group);
                    } else {
                      _selectedTargetGroups = {group}; // 单选
                    }
                  });
                  _loadExams();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                    ),
                  ),
                  child: Text(group,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          const Text('没有找到匹配的考试',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedIndustry = null;
                _selectedTargetGroups = {};
              });
              _loadExams();
            },
            child: const Text('清除所有筛选'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSearch(BuildContext context) async {
    final result = await showSearch<Exam?>(
      context: context,
      delegate: ExamSearchDelegate(),
    );
    if (result != null && mounted) {
      _navigateToDetail(context, result);
    }
  }

  void _navigateToDetail(BuildContext context, Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamDetailScreen(examId: exam.id),
      ),
    ).then((_) => _loadExams());
  }
}
