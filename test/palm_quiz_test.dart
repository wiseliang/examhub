import 'package:examhub/services/palm_quiz_service.dart';
import 'package:examhub/screens/palm_quiz_screen.dart';
import 'package:examhub/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sample = PalmBank(
    id: 'demo-bank',
    title: '二级 Python 练习资料（演示）',
    count: 12,
    shared: false,
  );
  test('名称匹配不伪造适配分数，支持正式名称中的Python关键词', () {
    expect(sample.matches('全国计算机等级考试二级 Python'), isTrue);
    expect(sample.matches('法律资格'), isFalse);
    expect(sample.matches('Python'), isTrue);
    expect(sample.matches(''), isTrue);
    expect(sample.binding('demo-user')['userId'], 'demo-user');
    expect(sample.binding('demo-user').containsKey('token'), isFalse);
  });
  test('读取列表必须先登录；登录会话只发往已有掌心接口', () async {
    final calls = <String>[];
    final client = PalmQuizClient(
      transport: (method, path, body, token) async {
        calls.add('$method $path');
        if (path == '/login') {
          expect(token, isEmpty);
          expect(body!['username'], 'demo');
          return {
            'token': 'demo-session',
            'user': {'id': 'demo-user', 'username': 'demo'},
          };
        }
        expect(token, 'demo-session');
        if (path == '/logout') return {'ok': true};
        return [
          {
            'id': sample.id,
            'title': sample.title,
            'count': sample.count,
            'shared': 0,
          },
        ];
      },
    );
    await expectLater(client.banks(), throwsException);
    expect(calls, isEmpty);
    await client.login('demo', 'demo-password');
    final banks = await client.banks();
    expect(banks.single.title, sample.title);
    await client.logout();
    expect(client.userId, isNull);
    await expectLater(client.banks(), throwsException);
    expect(calls, ['POST /login', 'GET /banks', 'POST /logout']);
  });
  test('退出请求失败仍清除本地会话，不把上一账号题库带入下一次登录', () async {
    final client = PalmQuizClient(
      transport: (method, path, body, token) async {
        if (path == '/login') {
          return {
            'token': 'demo-session',
            'user': {'id': 'demo-user', 'username': 'demo'},
          };
        }
        throw Exception('演示网络错误');
      },
    );
    await client.login('demo', 'demo-password');
    await expectLater(client.logout(), throwsException);
    expect(client.userId, isNull);
    expect(client.username, isNull);
  });
  testWidgets('演示账号登录、筛选和选择题库，320px放大字号不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final client = PalmQuizClient(
      transport: (method, path, body, token) async {
        if (path == '/login') {
          return {
            'token': 'demo-session',
            'user': {'id': 'demo-user', 'username': '演示账号'},
          };
        }
        return [
          {'id': sample.id, 'title': sample.title, 'count': 12, 'shared': 0},
        ];
      },
    );
    Map<String, dynamic>? chosen;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                chosen = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PalmQuizScreen(
                      exam: '全国计算机等级考试二级 Python',
                      client: client,
                    ),
                  ),
                );
              },
              child: const Text('查找题库'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('查找题库'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), 'demo-password');
    await tester.ensureVisible(find.text('登录并查找题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登录并查找题库'));
    await tester.pumpAndSettle();
    expect(find.text('已登录：演示账号'), findsOneWidget);
    await tester.ensureVisible(find.text(sample.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(sample.title));
    await tester.pumpAndSettle();
    expect(chosen!['id'], sample.id);
    expect(chosen!['userId'], 'demo-user');
    expect(chosen!.containsKey('token'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
