import 'dart:io';

import 'package:examhub/database/database_helper.dart';
import 'package:examhub/database/seed_data.dart';
import 'package:examhub/models/exam_session.dart';
import 'package:examhub/models/exam_timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  late Directory directory;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    directory = await Directory.systemTemp.createTemp('examhub-migration-');
    await databaseFactory.setDatabasesPath(directory.path);
    final legacy = await openDatabase(
      '${directory.path}/examhub.db',
      version: 1,
      onCreate: (db, _) async {
        for (final sql in File(
          'test/fixtures/schema_v1.sql',
        ).readAsStringSync().split(';')) {
          if (sql.trim().isNotEmpty) await db.execute(sql);
        }
        await SeedData.insertAll(db);
        await db.insert('local_follow', {'exam_id': 1});
        await db.insert('local_bookmark', {'exam_id': 1});
        await db.insert('browse_history', {'exam_id': 1});
      },
    );
    await legacy.close();
  });

  tearDownAll(() async {
    await helper.close();
    await directory.delete(recursive: true);
  });

  test('v1 升级保留考试、原始节点及全部个人数据，不猜测年份', () async {
    final db = await helper.database;
    expect(await db.getVersion(), 4);
    expect(await helper.getAllExams(), hasLength(40));
    expect(await helper.isFollowing(1), isTrue);
    expect(await helper.isBookmarked(1), isTrue);
    expect(await helper.getBrowseHistory(), hasLength(1));
    final session = (await helper.getSessions(1)).single;
    expect(session.year, isNull);
    expect(session.status, 'estimated');
    expect((await helper.getTimelines(1, sessionId: session.id)), hasLength(5));
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('同一考试多年度多地区多批次隔离，更新不删除其他安排和关注', () async {
    final verified = DateTime(2030, 1, 1);
    ExamSession session(
      String region,
      String batch, {
      int year = 2030,
      int? id,
    }) => ExamSession(
      id: id,
      examId: 1,
      year: year,
      region: region,
      batch: batch,
      status: 'confirmed',
      sourceUrl: 'https://example.com/notice',
      verifiedAt: verified,
    );
    final event = ExamTimeline(
      examId: 1,
      eventType: 'exam',
      periodDesc: '测试日期',
      date: DateTime(2030, 6, 1),
      isEstimated: false,
      status: 'confirmed',
      sourceUrl: 'https://example.com/notice',
      verifiedAt: verified,
    );
    final first = await helper.saveSession(session('北京', '第一批'), [event]);
    final second = await helper.saveSession(session('北京', '第二批'), [event]);
    final third = await helper.saveSession(
      session('上海', '第一批', year: 2031),
      [],
    );
    expect(await helper.getSessions(1, year: 2030, region: '北京'), hasLength(2));
    expect(await helper.getSessions(1, year: 2031), hasLength(1));
    await helper.saveSession(session('北京', '第一批', id: first), []);
    expect(await helper.getTimelines(1, sessionId: first), isEmpty);
    expect(await helper.getTimelines(1, sessionId: second), hasLength(1));
    expect(await helper.isFollowing(1), isTrue);
    await helper.close();
    expect(
      (await helper.getSessions(1)).map((s) => s.id),
      containsAll([first, second, third]),
    );
  });

  test('缺少来源或核验时间不能发布；跨考试写入和外键失败不污染数据', () async {
    expect(
      () => const ExamSession(
        examId: 1,
        year: 2030,
        status: 'confirmed',
      ).validate(),
      throwsArgumentError,
    );
    expect(
      () => const ExamSession(examId: 1, status: 'other').validate(),
      throwsArgumentError,
    );
    final count = (await helper.getSessions(1)).length;
    await expectLater(
      helper.saveSession(const ExamSession(examId: 1), [
        const ExamTimeline(examId: 2, eventType: 'exam', periodDesc: '测试'),
      ]),
      throwsArgumentError,
    );
    await expectLater(
      helper.saveSession(const ExamSession(examId: 99999), []),
      throwsA(isA<DatabaseException>()),
    );
    expect(await helper.getSessions(1), hasLength(count));
    expect(await helper.getSessions(99999), isEmpty);
    final existing = (await helper.getSessions(1)).first;
    await expectLater(
      helper.saveSession(ExamSession(id: existing.id, examId: 2), []),
      throwsStateError,
    );
  });

  test('预计、延期、取消和待公布节点不会出现在确定的近期日期列表', () async {
    final v = DateTime(2040);
    final ids = <int>[];
    for (final status in [
      'estimated',
      'postponed',
      'cancelled',
      'unpublished',
      'confirmed',
    ]) {
      ids.add(
        await helper.saveSession(
          ExamSession(
            examId: 1,
            year: 2040,
            region: '测试地区',
            status: status,
            sourceUrl: 'https://example.com/notice',
            verifiedAt: v,
          ),
          [
            ExamTimeline(
              examId: 1,
              eventType: 'exam',
              periodDesc: status,
              date: DateTime(2040, 6, 1),
              isEstimated: status != 'confirmed',
              status: status,
              sourceUrl: 'https://example.com/notice',
              verifiedAt: v,
            ),
          ],
        ),
      );
    }
    final events = await helper.getUpcomingEvents(
      from: DateTime(2040, 6, 1),
      days: 0,
    );
    expect(events.map((e) => e['period_desc']), ['confirmed']);
    final db = await helper.database;
    for (final id in ids) {
      await db.delete('exam_session', where: 'id = ?', whereArgs: [id]);
    }
  });
}
