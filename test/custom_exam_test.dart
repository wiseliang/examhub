import 'dart:io';

import 'package:examhub/database/database_helper.dart';
import 'package:examhub/database/seed_data.dart';
import 'package:examhub/database/session_schema.dart';
import 'package:flutter/services.dart';
import 'package:examhub/services/external_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  late Directory directory;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    directory = await Directory.systemTemp.createTemp('examhub-custom-');
    await databaseFactory.setDatabasesPath(directory.path);
    final legacy = await openDatabase(
      '${directory.path}/examhub.db',
      version: 2,
      onCreate: (db, _) async {
        for (final sql in File(
          'test/fixtures/schema_v1.sql',
        ).readAsStringSync().split(';')) {
          if (sql.trim().isNotEmpty) await db.execute(sql);
        }
        await SeedData.insertAll(db);
        await migrateSessions(db);
        await db.insert('local_follow', {'exam_id': 1, 'remind_signup': 0});
      },
    );
    await legacy.close();
  });
  tearDownAll(() async {
    await helper.close();
    await directory.delete(recursive: true);
  });

  test('v2 升级 v3 保留公开目录和关注偏好', () async {
    final db = await helper.database;
    expect(await db.getVersion(), 3);
    expect(await helper.getAllExams(), hasLength(40));
    expect((await helper.getExamById(1))!.isCustom, isFalse);
    final follow = await db.query('local_follow', where: 'exam_id = 1');
    expect(follow.single['remind_signup'], 0);
  });
  test('未收录考试可以添加、搜索、自动关注并在重开后保留', () async {
    final target = DateTime(2030, 8, 10);
    final id = await helper.addCustomExam(
      name: '  单位   招聘考试  ',
      industry: '招聘',
      targetDate: target,
      officialWebsite: 'https://example.com/notice',
    );
    expect(id, lessThan(0));
    final exam = (await helper.getExamById(id))!;
    expect(exam.name, '单位 招聘考试');
    expect(exam.isCustom, isTrue);
    expect(exam.targetDate, target);
    expect(await helper.isFollowing(id), isTrue);
    expect(await helper.searchExams('招聘考试'), hasLength(1));
    await helper.close();
    expect((await helper.getExamById(id))!.isCustom, isTrue);
    final again = await helper.addCustomExam(name: '单位 招聘考试');
    expect(again, id);
  });
  test('已有考试名称复用原 ID，不覆盖原资料和提醒设置', () async {
    final id = await helper.addCustomExam(
      name: 'cpa',
      officialWebsite: 'https://example.com/ignore',
    );
    expect(id, 1);
    expect(
      (await helper.getExamById(1))!.officialWebsite,
      'https://www.cicpa.org.cn',
    );
    final follow = await (await helper.database).query(
      'local_follow',
      where: 'exam_id = 1',
    );
    expect(follow.single['remind_signup'], 0);
  });
  test('拒绝空名称与非网页链接，不写入残留考试', () async {
    final count = (await helper.getAllExams()).length;
    await expectLater(helper.addCustomExam(name: ' '), throwsArgumentError);
    await expectLater(
      helper.addCustomExam(name: '测试', officialWebsite: 'javascript:alert(1)'),
      throwsArgumentError,
    );
    expect(await helper.getAllExams(), hasLength(count));
  });
  test('个人档案可编辑与删除，公共档案受到保护', () async {
    final id = await helper.addCustomExam(name: '可编辑的个人考试');
    await helper.bookmarkExam(id); await helper.recordBrowse(id);
    await helper.updateCustomExam(id: id, name: '修改后的考试', industry: '技能', officialWebsite: 'https://example.com/', targetDate: DateTime(2031, 2, 3));
    expect((await helper.getExamById(id))!.name, '修改后的考试');
    expect(await helper.isFollowing(id), isTrue);
    await expectLater(helper.updateCustomExam(id: 1, name: '改公共考试', industry: '', officialWebsite: ''), throwsStateError);
    await expectLater(helper.deleteCustomExam(1), throwsStateError);
    await helper.deleteCustomExam(id);
    expect(await helper.getExamById(id), isNull); expect(await helper.isFollowing(id), isFalse); expect(await helper.isBookmarked(id), isFalse);
    expect(await (await helper.database).rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });
  test('外部入口只接受网页 URL，不将本地考试 ID 冒充题库 ID', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ExternalActions.channel, (call) async {
          calls.add(call);
          return true;
        });
    expect(await ExternalActions.openUrl('javascript:alert(1)'), isFalse);
    expect(
      await ExternalActions.openUrl('https://user:secret@example.com/'),
      isFalse,
    );
    expect(await ExternalActions.openUrl(ExternalActions.quizUrl), isTrue);
    expect(calls.single.method, 'openExternal');
    expect(calls.single.arguments, {
      'url': 'https://wiseliang.cloud/palm-quiz/',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ExternalActions.channel, null);
  });
}
