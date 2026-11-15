import 'package:material_ui/material_ui.dart';

import '../services/palm_quiz_service.dart';
import '../services/external_actions.dart';
import '../theme/app_theme.dart';

class PalmQuizScreen extends StatefulWidget {
  final String exam;
  final PalmQuizClient? client;
  const PalmQuizScreen({super.key, this.exam = '', this.client});
  @override
  State<PalmQuizScreen> createState() => _PalmQuizScreenState();
}

class _PalmQuizScreenState extends State<PalmQuizScreen> {
  late final PalmQuizClient _client;
  final _name = TextEditingController(), _password = TextEditingController();
  late final TextEditingController _search;
  List<PalmBank> _banks = [];
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState(); _client = widget.client ?? PalmQuizClient.shared;
    _search = TextEditingController(text: widget.exam);
    if (_client.userId != null) _load();
  }
  @override
  void dispose() { _name.dispose(); _password.dispose(); _search.dispose(); super.dispose(); }

  String _friendly(Object e) => e.toString().replaceFirst('Exception: ', '');
  void _report(Object error) {
    if (!mounted) return;
    final message = _friendly(error);
    setState(() => _error = message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  Future<void> _login() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _client.login(_name.text, _password.text);
      if (!mounted) return;
      _password.clear();
      final banks = await _client.banks();
      if (mounted) setState(() => _banks = banks);
    } catch (e) { _report(e); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _load() async {
    setState(() { _busy = true; _error = null; });
    try { final banks = await _client.banks(); if (mounted) setState(() => _banks = banks); }
    catch (e) { if (mounted) setState(() { _banks = []; _error = _friendly(e); }); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _logout() async {
    if (_busy) return;
    setState(() => _busy = true);
    try { await _client.logout(); } catch (_) { /* 本地会话仍会清除。 */ }
    if (mounted) setState(() { _banks = []; _busy = false; _error = null; });
  }
  @override
  Widget build(BuildContext context) {
    final loggedIn = _client.userId != null;
    final results = _banks.where((b) => b.matches(_search.text)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('我的掌心题库'), actions: [if (loggedIn) IconButton(onPressed: _busy ? null : _load, tooltip: '刷新题库', icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('把已有题库用起来', style: AppTheme.heading2),
        const SizedBox(height: 10),
        const Text('登录掌心刷题后，读取你有权访问的题库名称和题数，选一份作为当前备考的参考题库。', style: AppTheme.bodySmall),
        const SizedBox(height: 20),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        if (_busy) const LinearProgressIndicator(),
        if (!loggedIn) ...[
          TextField(controller: _name, autocorrect: false, decoration: const InputDecoration(labelText: '掌心刷题账号'), autofillHints: const [AutofillHints.username], maxLength: 30),
          const SizedBox(height: 12),
          TextField(controller: _password, obscureText: true, autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(labelText: '密码'), autofillHints: const [AutofillHints.password]),
          const SizedBox(height: 18),
          FilledButton(onPressed: _busy ? null : _login, child: const Text('登录并查找题库')),
          const SizedBox(height: 10),
          const Text('登录信息只发送到掌心刷题。密码和登录会话不保存到本地数据库；关闭应用后重新登录。', style: AppTheme.bodySmall),
          TextButton(onPressed: () => ExternalActions.open(context, ExternalActions.quizUrl), child: const Text('前往掌心刷题注册或管理账号')),
        ] else ...[
          Row(children: [Expanded(child: Text('已登录：${_client.username}', style: AppTheme.heading3)), TextButton(onPressed: _busy ? null : _logout, child: const Text('退出登录'))]),
          const SizedBox(height: 12),
          TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: '按考试或题库名称查找', prefixIcon: Icon(Icons.search))),
          const SizedBox(height: 12),
          const Text('名称相符不代表年份、大纲或答案质量已核实。请结合考试依据确认后再使用。', style: AppTheme.bodySmall),
          if (!_busy && _banks.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('当前账号还没有可访问的题库。可以先在掌心刷题导入资料，再回来刷新。')),
          if (!_busy && _banks.isNotEmpty && results.isEmpty) ...[
            const Padding(padding: EdgeInsets.only(top: 20), child: Text('暂未找到名称相关的题库，可以缩短关键词或查看全部。')),
            TextButton(onPressed: () => setState(() => _search.clear()), child: const Text('查看全部题库')),
          ],
          for (final bank in results) ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            title: Text(bank.title), subtitle: Text('${bank.count} 题，${bank.shared ? '共享题库' : '个人题库'}；版本待核对'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () => Navigator.pop(context, bank.binding(_client.userId!)),
          ),
        ],
      ]),
    );
  }
}
