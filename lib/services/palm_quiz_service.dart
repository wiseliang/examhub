import 'dart:convert';
import 'dart:io';

typedef PalmTransport = Future<dynamic> Function(String method, String path, Map<String, dynamic>? body, String token);

class PalmBank {
  final String id, title;
  final int count;
  final bool shared;
  const PalmBank({required this.id, required this.title, required this.count, required this.shared});
  factory PalmBank.fromJson(Map<String, dynamic> value) {
    if (value['id'] is! String || value['title'] is! String || value['count'] is! int || (value['count'] as int) < 0) {
      throw Exception('题库列表格式异常，请稍后重试。');
    }
    return PalmBank(id: value['id'] as String, title: value['title'] as String, count: value['count'] as int, shared: value['shared'] == 1 || value['shared'] == true);
  }
  bool matches(String query) {
    String normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]'), '');
    final needle = normalize(query), name = normalize(title);
    if (needle.isEmpty) return true;
    if (name.contains(needle) || (name.length >= 4 && needle.contains(name))) return true;
    final words = RegExp(r'[a-z][a-z0-9]{1,}', caseSensitive: false).allMatches(query).map((m) => m.group(0)!.toLowerCase());
    return words.any((word) => RegExp('(^|[^a-z0-9])${RegExp.escape(word)}([^a-z0-9]|\$)').hasMatch(title.toLowerCase()));
  }
  Map<String, dynamic> binding(String userId) => {'id': id, 'title': title, 'count': count, 'shared': shared, 'userId': userId};
}

/// 使用掌心刷题现有登录与元数据接口；密码和会话仅在当前进程中使用。
/// 不向备考研究服务或模型发送登录信息、题目正文及用户题库列表。
class PalmQuizClient {
  static final shared = PalmQuizClient();
  static const baseUrl = 'https://wiseliang.cloud/palm-quiz/api';
  final PalmTransport? transport;
  String _token = '';
  String? userId, username;
  PalmQuizClient({this.transport});

  Future<dynamic> _request(String method, String path, [Map<String, dynamic>? body]) async {
    try {
      if (transport != null) return await transport!(method, path, body, _token);
      final client = HttpClient()..userAgent = 'ExamHub/1.4 (+https://wiseliang.cloud; Android)'..connectionTimeout = const Duration(seconds: 15);
      try {
        final request = await client.openUrl(method, Uri.parse('$baseUrl$path')).timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        request.headers.contentType = ContentType.json;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (_token.isNotEmpty) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_token');
        if (body != null) request.write(jsonEncode(body));
        final response = await request.close().timeout(const Duration(seconds: 20));
        final bytes = <int>[];
        await for (final chunk in response.timeout(const Duration(seconds: 20))) {
          if (bytes.length + chunk.length > 2 * 1024 * 1024) throw Exception('题库列表过大，请在掌心刷题中查看。');
          bytes.addAll(chunk);
        }
        if (response.statusCode >= 300 && response.statusCode < 400) throw Exception('掌心刷题地址发生跳转，请稍后重试。');
        dynamic value;
        try { value = jsonDecode(utf8.decode(bytes)); } catch (_) { throw Exception('掌心刷题暂时不可用，请稍后重试。'); }
        if (response.statusCode == 401) { _token = ''; userId = null; username = null; }
        if (response.statusCode >= 400) throw Exception(value is Map ? value['error'] ?? '掌心刷题请求失败。' : '掌心刷题请求失败。');
        return value;
      } finally { client.close(force: true); }
    } on SocketException { throw Exception('无法连接掌心刷题，请检查网络。'); }
  }

  Future<void> login(String name, String password) async {
    if (name.trim().isEmpty || name.length > 30 || password.isEmpty || password.length > 200) throw Exception('请填写有效的掌心刷题账号和密码。');
    final result = await _request('POST', '/login', {'username': name.trim(), 'password': password});
    if (result is! Map || result['token'] is! String || (result['token'] as String).isEmpty || result['user'] is! Map || result['user']['id'] is! String || result['user']['username'] is! String) throw Exception('登录结果异常，请重试。');
    _token = result['token'] as String; userId = result['user']['id'] as String; username = result['user']['username'] as String;
  }

  Future<List<PalmBank>> banks() async {
    if (_token.isEmpty || userId == null) throw Exception('请先登录掌心刷题。');
    final result = await _request('GET', '/banks');
    if (result is! List) throw Exception('题库列表格式异常，请稍后重试。');
    return result.map((b) => PalmBank.fromJson(Map<String, dynamic>.from(b as Map))).toList();
  }

  Future<void> logout() async {
    try { if (_token.isNotEmpty) await _request('POST', '/logout', {}); }
    finally { _token = ''; userId = null; username = null; }
  }
}
