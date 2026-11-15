import 'dart:convert';

import 'package:examhub/models/exam.dart';
import 'package:examhub/models/exam_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SQLite JSON 往返保留引号、换行、反斜杠和科目时长', () {
    const exam = Exam(
      id: 1,
      name: '测试',
      fullName: '测试考试',
      category: '准入类',
      industry: '法律',
      targetGroups: ['应届', '带"引号"'],
      organizingBody: '单位',
      officialWebsite: 'https://example.com',
      difficulty: 3,
      goldContent: 3.5,
      description: '简介',
      eligibility: '条件',
      examFormat: '机考',
      subjects: [ExamSubject(name: '科目"一"\n新行', format: '机考', duration: 180)],
      tags: ['路径\\文件', '多\n行'],
      logoAssetPath: 'assets/test.png',
    );
    final stored = exam.toMap();
    expect(jsonDecode(stored['subjects'] as String), isA<List>());
    final restored = Exam.fromMap(stored);
    expect(restored.targetGroups, exam.targetGroups);
    expect(restored.tags, exam.tags);
    expect(restored.subjects.single.name, exam.subjects.single.name);
    expect(restored.subjects.single.duration, 180);
    expect(restored.logoAssetPath, exam.logoAssetPath);
  });

  test('通知解析数据库中的 JSON 字符串及异常值', () {
    final points = NoticeKeyPoint.fromJsonList(
      '[{"type":"时间变更","content":"报名延长"}]',
    );
    expect(points.single.content, '报名延长');
    expect(NoticeKeyPoint.fromJsonList('invalid'), isEmpty);
    expect(ExamSubject.fromJsonList('[invalid'), isEmpty);
  });

  test('倒计时按日历日计算而非不足 24 小时截断', () {
    final timeline = ExamTimeline(
      examId: 1,
      eventType: 'exam',
      periodDesc: '测试',
      date: DateTime(2030, 6, 11),
    );
    expect(timeline.daysUntil(DateTime(2030, 6, 10, 23, 59)), 1);
    expect(timeline.daysUntil(DateTime(2030, 6, 11, 23, 59)), 0);
  });
}
