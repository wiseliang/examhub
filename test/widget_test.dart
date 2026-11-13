import 'dart:io';

import 'package:examhub/app.dart';
import 'package:examhub/database/database_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  late Directory directory;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    directory = await Directory.systemTemp.createTemp('examhub-test-');
    await databaseFactory.setDatabasesPath(directory.path);
    await helper.database;
  });

  tearDownAll(() async {
    await helper.close();
    await directory.delete(recursive: true);
  });

  setUp(() async {
    final db = await helper.database;
    for (final table in ['local_follow', 'local_bookmark', 'browse_history']) {
      await db.delete(table);
    }
  });

  test('初始化和并发读取保留全部 40 个考试及 CPA 科目', () async {
    final connections = await Future.wait(
      List.generate(3, (_) => helper.database),
    );
    expect(connections.every((db) => identical(db, connections.first)), isTrue);
    final exams = await helper.getAllExams();
    expect(exams, hasLength(40));
    final cpa = await helper.getExamById(1);
    expect(cpa!.subjects, hasLength(7));
    expect(cpa.targetGroups, contains('应届'));
    expect(await helper.searchExams('CPA'), hasLength(1));
    final filtered = await helper.filterExams(
      industry: '法律',
      targetGroup: '应届',
    );
    expect(filtered, isNotEmpty);
    expect(
      filtered.every(
        (exam) => exam.industry == '法律' && exam.targetGroups.contains('应届'),
      ),
      isTrue,
    );
  });

  test('关注、收藏去重，取消后移除；清空历史不影响其他记录', () async {
    await helper.followExam(1);
    await helper.followExam(1);
    await helper.bookmarkExam(1);
    await helper.bookmarkExam(1);
    await helper.recordBrowse(1);
    await helper.recordBrowse(1);
    expect(await helper.getFollowedExams(), hasLength(1));
    expect(await helper.getBookmarkedExams(), hasLength(1));
    expect(await helper.getBrowseHistory(), hasLength(1));
    await helper.close();
    expect(await helper.getFollowedExams(), hasLength(1));
    expect(await helper.getBookmarkedExams(), hasLength(1));
    expect(await helper.getAllExams(), hasLength(40));
    await helper.clearBrowseHistory();
    expect(await helper.getBrowseHistory(), isEmpty);
    expect(await helper.isFollowing(1), isTrue);
    expect(await helper.isBookmarked(1), isTrue);
    await helper.unfollowExam(1);
    await helper.unbookmarkExam(1);
    expect(await helper.getFollowedExams(), isEmpty);
    expect(await helper.getBookmarkedExams(), isEmpty);
  });

  test('近期节点包含今天和截止当天，排除过去及超出范围的日期', () async {
    final db = await helper.database;
    const dates = [
      '2030-06-09',
      '2030-06-10',
      '2030-06-12T00:00:00.000',
      '2030-06-13',
    ];
    final ids = <int>[];
    try {
      for (final date in dates) {
        ids.add(
          await db.insert('exam_timeline', {
            'exam_id': 1,
            'event_type': 'exam',
            'period_desc': '测试',
            'date': date,
            'is_estimated': 0,
          }),
        );
      }
      final events = await helper.getUpcomingEvents(
        days: 2,
        from: DateTime(2030, 6, 10, 23, 59),
      );
      expect(events.map((event) => event['date']), dates.sublist(1, 3));
    } finally {
      for (final id in ids) {
        await db.delete('exam_timeline', where: 'id = ?', whereArgs: [id]);
      }
    }
  });

  testWidgets('实际 App 可浏览首页、搜索 CPA 并进入包含科目的详情', (tester) async {
    await tester.pumpWidget(const ExamHubApp());
    await tester.pumpAndSettle();
    expect(find.text('考试通'), findsOneWidget);
    expect(find.text('热门考试'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'CPA');
    await tester.pumpAndSettle();
    await tester.tap(find.text('CPA').first);
    await tester.pumpAndSettle();
    expect(find.text('概览'), findsOneWidget);
    expect(find.text('关注考试'), findsOneWidget);
    await tester.tap(find.text('关注考试'));
    await tester.pumpAndSettle();
    expect(await helper.isFollowing(1), isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    expect(find.text('🔔 关注的考试'), findsOneWidget);
    expect(find.text('CPA'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
