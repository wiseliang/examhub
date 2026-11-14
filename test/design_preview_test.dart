import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:examhub/app.dart';
import 'package:examhub/screens/assistant_screen.dart';
import 'package:examhub/services/assistant_service.dart';
import 'package:examhub/theme/app_theme.dart';
import 'package:examhub/database/database_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  late Directory directory;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    directory = await Directory.systemTemp.createTemp('examhub-design-');
    await databaseFactory.setDatabasesPath(directory.path);
    await helper.database;
    await helper.followExam(1);
    final font = File('.test-fonts/cjk.otf');
    if (font.existsSync()) {
      final loader = FontLoader('Noto Sans CJK SC')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  tearDownAll(() async {
    await helper.close();
    await directory.delete(recursive: true);
  });

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (!File('.test-fonts/cjk.otf').existsSync()) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/ui-previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('真实页面预览与个人考试闭环（390px）', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const ExamHubApp()),
    );
    await capture(tester, key, '备考首页');
    await tester.tap(find.text('考试库').last);
    await tester.pumpAndSettle();
    await capture(tester, key, '考试库');
    await tester.enterText(find.byType(TextField), '未收录的单位考试');
    await tester.pumpAndSettle();
    expect(find.text('添加这个考试'), findsOneWidget);
    await capture(tester, key, '未收录考试');
    await tester.tap(find.text('添加这个考试'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '未收录的单位考试'), findsOneWidget);
    await capture(tester, key, '添加考试');
    await tester.ensureVisible(find.text('添加并关注'));
    await tester.tap(find.text('添加并关注'));
    await tester.pumpAndSettle();
    expect(find.text('个人添加'), findsOneWidget);
    expect((await helper.searchExams('未收录的单位考试')).single.isCustom, isTrue);
    await capture(tester, key, '个人考试档案');
    await tester.tap(find.text('刷题准备'));
    await tester.pumpAndSettle();
    expect(find.text('复制考试名称并打开掌心刷题'), findsOneWidget);
    await capture(tester, key, '掌心刷题入口');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    expect(find.text('未收录的单位考试'), findsOneWidget);
    await capture(tester, key, '我的考试');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('助手目标与真实联网实测结果页面预览', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AssistantScreen(),
        ),
      ),
    );
    await capture(tester, key, '备考助手目标');
    await tester.pumpWidget(const SizedBox.shrink());
    final sample = jsonDecode(
      File('test/fixtures/assistant_live_research_20261114.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    await AssistantStore().write('assistant:freeform', {
      'goal': sample['goal'],
      'result': sample['result'],
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AssistantScreen(),
        ),
      ),
    );
    await capture(tester, key, '备考助手联网实测结果');
    await tester.ensureVisible(find.text('每日复习任务'));
    await capture(tester, key, '备考助手每日任务');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('320px 及放大字号时导航和考试库不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ExamHubApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('考试库').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
