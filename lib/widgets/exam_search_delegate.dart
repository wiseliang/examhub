import 'package:material_ui/material_ui.dart';

import '../database/database_helper.dart';
import '../models/exam.dart';
import '../screens/custom_exam_screen.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

class ExamSearchDelegate extends SearchDelegate<Exam?> {
  @override
  String get searchFieldLabel => '搜索考试名称、行业';
  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: '清除搜索',
        icon: const Icon(Icons.close_rounded),
        onPressed: () => query = '',
      ),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: '返回',
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, null),
  );
  @override
  Widget buildResults(BuildContext context) => _results(context);
  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
  Widget _results(BuildContext context) {
    if (query.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('从一个方向开始', style: AppTheme.heading2),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['教师', '会计', '法律', '计算机']
                  .map(
                    (word) => ActionChip(
                      label: Text(word),
                      onPressed: () {
                        query = word;
                        showResults(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }
    return FutureBuilder<List<Exam>>(
      future: DatabaseHelper().searchExams(query.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('搜索未完成，请重新输入后再试。'));
        }
        final exams = snapshot.data ?? [];
        if (exams.isEmpty) {
          return ListView(
            padding: const EdgeInsets.only(top: 28),
            children: [
              EmptyPanel(
                title: '没有找到“${query.trim()}”',
                message: '把它加入自己的考试列表，继续准备。',
                action: '添加这个考试',
                onTap: () async {
                  final id = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CustomExamScreen(initialName: query.trim()),
                    ),
                  );
                  if (id != null && context.mounted) {
                    final exam = await DatabaseHelper().getExamById(id);
                    if (context.mounted) close(context, exam);
                  }
                },
                icon: Icons.search_off_rounded,
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: exams.length,
          separatorBuilder: (_, _) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),
          itemBuilder: (context, index) => ExamRow(
            exam: exams[index],
            onTap: () => close(context, exams[index]),
          ),
        );
      },
    );
  }
}
