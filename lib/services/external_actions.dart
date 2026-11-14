import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/exam.dart';

class ExternalActions {
  static const channel = MethodChannel('cloud.wiseliang.examhub/external');
  static const quizUrl = 'https://wiseliang.cloud/palm-quiz/';
  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return false;
    }
    try {
      return await channel.invokeMethod<bool>('openExternal', {
            'url': uri.toString(),
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> open(BuildContext context, String url) async {
    final opened = await openUrl(url);
    if (!opened && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('打开网址'),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('复制网址'),
            ),
          ],
        ),
      );
    }
  }

  static Future<void> practice(BuildContext context, {Exam? exam}) async {
    if (exam != null) {
      await Clipboard.setData(ClipboardData(text: exam.fullName));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已复制考试名称，请在掌心刷题选择或导入对应题库。')));
    }
    if (context.mounted) await open(context, quizUrl);
  }
}
