import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/exam.dart';
import '../screens/exam_detail_screen.dart';
import '../theme/app_theme.dart';

/// 考试搜索代理
class ExamSearchDelegate extends SearchDelegate<Exam?> {
  final DatabaseHelper _db = DatabaseHelper();

  @override
  String get searchFieldLabel => '搜索考试/行业/主办单位...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.backgroundColor,
        hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return _buildTips(context);
    }

    return FutureBuilder<List<Exam>>(
      future: _db.searchExams(query.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('搜索出错: ${snapshot.error}'));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: AppTheme.textLight),
                const SizedBox(height: 12),
                Text('未找到"$query"相关考试',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Text('请尝试其他关键词搜索',
                    style: AppTheme.caption),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72, endIndent: 16),
          itemBuilder: (context, index) {
            final exam = results[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.getIndustryColor(exam.industry)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  exam.name.length > 3
                      ? exam.name.substring(0, 3)
                      : exam.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: exam.name.length > 3 ? 10 : 13,
                    color: AppTheme.getIndustryColor(exam.industry),
                  ),
                ),
              ),
              title: Text(exam.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(exam.organizingBody,
                  style: AppTheme.caption, maxLines: 1),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: AppTheme.accentColor),
                  const SizedBox(width: 2),
                  Text('${exam.goldContent}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              onTap: () => close(context, exam),
            );
          },
        );
      },
    );
  }

  Widget _buildTips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 试试搜索', style: AppTheme.body?.copyWith(
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'CPA', '法考', '建造师', 'CFA', '会计',
              '建筑', '金融', 'IT', '法律', '医疗',
            ].map((keyword) => ActionChip(
                  label: Text(keyword),
                  onPressed: () {
                    query = keyword;
                    showResults(context);
                  },
                )).toList(),
          ),
          const SizedBox(height: 24),
          Text('热门搜索', style: AppTheme.body?.copyWith(
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 8),
          Text('教师资格证 · 注册会计师 · 一级建造师 · PMP',
              style: AppTheme.caption),
        ],
      ),
    );
  }
}
