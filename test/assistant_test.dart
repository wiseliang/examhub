import 'dart:io';

import 'package:examhub/database/database_helper.dart';
import 'package:examhub/screens/assistant_screen.dart';
import 'package:examhub/services/assistant_service.dart';
import 'package:examhub/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FixtureApi extends AssistantApi {
  final Map<String, dynamic> result;
  final bool fail;
  int starts = 0;
  FixtureApi(this.result, {this.fail = false});
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    if (method == 'POST') {
      starts++;
      if (fail) throw Exception('测试：服务不可用');
      return {'id': 'fixture'};
    }
    return {'status': 'completed', 'result': result};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final store = AssistantStore();
  final today = DateTime.now();
  final date =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final goal = <String, dynamic>{
    'exam': '测试用自定义考试',
    'region': '上海',
    'level': '零基础',
    'preferences': '免费',
    'targetDate': today
        .add(const Duration(days: 30))
        .toIso8601String()
        .substring(0, 10),
    'minutes': 60,
  };
  Map<String, dynamic> fixture() => {
    'summary': '这是测试固定数据，不是实际检索结论。',
    'searchedAt': '测试时间',
    'searches': 1,
    'uncertainties': ['测试未核验事项'],
    'sources': [],
    'banks': [],
    'plan': {
      'days': 1,
      'notice': '测试计划',
      'tasks': [
        {
          'id': 'fixture-task',
          'date': date,
          'title': '测试基础概念',
          'subject': '基础',
          'minutes': 60,
          'done': false,
        },
      ],
    },
  };
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    directory = await Directory.systemTemp.createTemp(
      'examhub-assistant-test-',
    );
    await databaseFactory.setDatabasesPath(directory.path);
    await DatabaseHelper().database;
  });
  tearDownAll(() async {
    await DatabaseHelper().close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    final db = await DatabaseHelper().database;
    await db.delete('assistant_state');
    AssistantApi.endpoint = '';
    AssistantApi.accessCode = '';
  });
  Future<void> open(WidgetTester tester, {AssistantApi? api}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AssistantScreen(api: api),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('计划持久化并且不会保存访问码', () async {
    await store.write('assistant:freeform', {
      'goal': goal,
      'result': fixture(),
    });
    await DatabaseHelper().close();
    expect(
      (await store.read('assistant:freeform'))!['goal']['exam'],
      goal['exam'],
    );
    expect(await store.read('connection'), isNull);
  });
  testWidgets('320px 放大字号下目标表单无溢出，未填名称不能提交', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final api = FixtureApi(fixture());
    await open(tester, api: api);
    await tester.ensureVisible(find.text('检索资料并规划复习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检索资料并规划复习'));
    await tester.pumpAndSettle();
    expect(api.starts, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('真实异步流程接收结果并打卡，重开保留进度', (tester) async {
    await store.write('assistant:freeform', {'goal': goal});
    final api = FixtureApi(fixture());
    await open(tester, api: api);
    await tester.ensureVisible(find.text('检索资料并规划复习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检索资料并规划复习'));
    await tester.pumpAndSettle();
    expect(api.starts, 1);
    expect(find.text('这是测试固定数据，不是实际检索结论。'), findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    final saved = (await store.read('assistant:freeform'))!;
    expect(saved['result']['plan']['tasks'][0]['done'], isTrue);
    expect(saved.containsKey('job'), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await open(tester, api: api);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('服务失败保留已填写目标并允许重试，不显示虚构结果', (tester) async {
    await store.write('assistant:freeform', {'goal': goal});
    final api = FixtureApi(fixture(), fail: true);
    await open(tester, api: api);
    await tester.ensureVisible(find.text('检索资料并规划复习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检索资料并规划复习'));
    await tester.pumpAndSettle();
    expect(api.starts, 1);
    expect(find.text('测试：服务不可用'), findsWidgets);
    expect(find.text('这是测试固定数据，不是实际检索结论。'), findsNothing);
    expect(
      (await store.read('assistant:freeform'))!['goal']['exam'],
      goal['exam'],
    );
  });
}
