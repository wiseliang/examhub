import 'package:examhub/services/study_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('补排跳过休息日并保留完成记录，不超过每日预算', () {
    final original = <String, dynamic>{
      'tasks': [
        {'id': 'done', 'date': '2030-06-01', 'minutes': 45, 'done': true},
        {'id': 'overdue', 'date': '2030-05-01', 'minutes': 45, 'done': false},
        {'id': 'review', 'date': '2030-05-01', 'minutes': 15, 'done': false},
      ],
    };
    final result = rescheduleStudyPlan(original, {
      'targetDate': '2030-06-08',
      'minutes': 60,
      'studyDays': [6, 7],
    }, DateTime(2030, 6, 1));
    final tasks = result['tasks'] as List;
    expect(tasks[0]['date'], '2030-06-01');
    for (final date in tasks.map((t) => t['date']).toSet()) {
      expect(
        tasks
            .where((t) => t['date'] == date)
            .fold<int>(0, (s, t) => s + (t['minutes'] as int)),
        lessThanOrEqualTo(60),
      );
      expect([6, 7], contains(DateTime.parse(date as String).weekday));
    }
    expect((original['tasks'] as List)[1]['date'], '2030-05-01');
    expect(tasks.map((t) => t['id']), ['done', 'overdue', 'review']);
  });
  test('日期已过时明确显示待安排，不悄悄丢弃任务', () {
    final result = rescheduleStudyPlan(
      {
        'tasks': [
          {
            'id': 'remaining',
            'date': '2020-01-01',
            'minutes': 60,
            'done': false,
          },
        ],
      },
      {'targetDate': '2020-01-02', 'minutes': 60},
      DateTime(2030, 6, 1),
    );
    expect((result['tasks'] as List).single['date'], '待安排');
    expect(result['notice'], contains('放不下 1 项'));
  });
}
