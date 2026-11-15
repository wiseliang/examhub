/// 只移动未完成任务，已完成记录和任务编号保持不变；不调用模型。
Map<String, dynamic> rescheduleStudyPlan(
  Map<String, dynamic> original,
  Map<String, dynamic> goal,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final deadline = DateTime.parse(goal['targetDate'] as String);
  final minutes = goal['minutes'] as int;
  final studyDays = ((goal['studyDays'] as List?) ?? [1, 2, 3, 4, 5, 6, 7])
      .cast<int>();
  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final tasks = (original['tasks'] as List)
      .map((t) => Map<String, dynamic>.from(t as Map))
      .toList();
  final used = <String, int>{};
  for (final task in tasks.where((t) => t['done'] == true)) {
    final date = task['date'] as String;
    used[date] = (used[date] ?? 0) + (task['minutes'] as int);
  }
  final available = <String>[];
  for (
    var date = today;
    date.isBefore(deadline);
    date = DateTime(date.year, date.month, date.day + 1)
  ) {
    if (studyDays.contains(date.weekday)) {
      available.add(day(date));
    }
  }
  var missing = 0;
  var earliest = 0;
  for (final task in tasks.where((t) => t['done'] != true)) {
    final duration = task['minutes'] as int;
    final candidates = available
        .skip(earliest)
        .where((date) => (used[date] ?? 0) + duration <= minutes);
    if (candidates.isEmpty) {
      task['date'] = '待安排';
      missing++;
    } else {
      final date = candidates.first;
      earliest = available.indexOf(date);
      task['date'] = date;
      used[date] = (used[date] ?? 0) + duration;
    }
  }
  return {
    ...original,
    'tasks': tasks,
    'notice': missing > 0
        ? '已保留完成记录，但截止日前放不下 $missing 项任务。请调整截止日、每天时长或学习日后重新研究。'
        : '已保留完成记录，从今天起按原学习日和每日时间预算重新安排未完成任务。',
  };
}
