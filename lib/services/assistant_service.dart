import 'dart:convert';
import 'dart:io';

import '../database/database_helper.dart';

class AssistantStore {
  Future<Map<String, dynamic>?> read(String key) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(
      'assistant_state',
      where: 'id = ?',
      whereArgs: [key],
    );
    return rows.isEmpty
        ? null
        : jsonDecode(rows.first['body'] as String) as Map<String, dynamic>;
  }

  Future<void> write(String key, Map<String, dynamic> value) async {
    final db = await DatabaseHelper().database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO assistant_state (id, body) VALUES (?, ?)',
      [key, jsonEncode(value)],
    );
  }
}

class AssistantApi {
  static String endpoint = '';
  // 个人访问码仅保留在本次进程内，不写入安装包、日志或本地数据库。
  static String accessCode = '';

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        accessCode.isEmpty) {
      throw Exception('请先连接 HTTPS 备考服务并填写个人访问码。');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .openUrl(
            method,
            Uri.parse('${endpoint.replaceAll(RegExp(r'/+$'), '')}$path'),
          )
          .timeout(const Duration(seconds: 20));
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessCode',
      );
      request.headers.contentType = ContentType.json;
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      var bytes = 0;
      final chunks = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        bytes += chunk.length;
        if (bytes > 2 * 1024 * 1024) throw Exception('服务返回的数据过大。');
        chunks.addAll(chunk);
      }
      final data = jsonDecode(utf8.decode(chunks)) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw Exception(data['error'] ?? '服务请求失败，请重试。');
      }
      return data;
    } on SocketException {
      throw Exception('无法连接备考服务，请检查网络和服务地址。');
    } on HandshakeException {
      throw Exception('服务证书无效，请联系服务管理员。');
    } finally {
      client.close(force: true);
    }
  }
}
