import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/assistant_service.dart';
import '../services/external_actions.dart';
import '../theme/app_theme.dart';

class AssistantScreen extends StatefulWidget {
  final String initialExam;
  final AssistantApi? api;
  const AssistantScreen({super.key, this.initialExam = '', this.api});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _store = AssistantStore();
  final _form = GlobalKey<FormState>();
  final _exam = TextEditingController(),
      _region = TextEditingController(),
      _level = TextEditingController(),
      _preferences = TextEditingController(),
      _minutes = TextEditingController(text: '60');
  late final AssistantApi _api;
  DateTime? _date;
  Map<String, dynamic>? _document;
  String? _job, _error;
  String _message = '';
  bool _busy = false, _polling = false, _ready = false;
  int _week = 0;
  Set<int> _studyDays = {1, 2, 3, 4, 5, 6, 7};
  Timer? _timer;
  String get _key =>
      'assistant:${widget.initialExam.isEmpty ? 'freeform' : widget.initialExam}';
  Map<String, dynamic>? get _result =>
      _document?['result'] as Map<String, dynamic>?;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AssistantApi();
    _exam.text = widget.initialExam;
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in [_exam, _region, _level, _preferences, _minutes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final config = await _store.read('connection');
      if (AssistantApi.endpoint.isEmpty) {
        AssistantApi.endpoint = config?['endpoint'] as String? ?? '';
      }
      final document = await _store.read(_key);
      if (!mounted) return;
      _document = document;
      final goal = document?['goal'] as Map<String, dynamic>?;
      if (goal != null) {
        _exam.text = goal['exam'] as String;
        _region.text = goal['region'] as String;
        _level.text = goal['level'] as String;
        _preferences.text = goal['preferences'] as String;
        _minutes.text = '${goal['minutes']}';
        _date = DateTime.tryParse(goal['targetDate'] as String);
        _studyDays = ((goal['studyDays'] as List?) ?? [1, 2, 3, 4, 5, 6, 7]).cast<int>().toSet();
      }
      _job = document?['job'] as String?;
      _message = _job == null ? '' : '有未完成的研究，连接服务后可继续查看';
    } catch (_) {
      _error = '本地备考记录读取失败，请重试打开。';
    }
    if (mounted) {
      setState(() => _ready = true);
      if (_job != null && AssistantApi.accessCode.isNotEmpty) _resume();
    }
  }

  String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _friendly(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
  Future<void> _save() async {
    if (_document != null) await _store.write(_key, _document!);
  }

  Future<void> _connect() async {
    final address = TextEditingController(text: AssistantApi.endpoint);
    final code = TextEditingController(text: AssistantApi.accessCode);
    final settings = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接备考服务'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('填写管理员提供的 HTTPS 地址和个人访问码。访问码仅在本次打开期间保留。'),
              const SizedBox(height: 16),
              TextField(
                controller: address,
                decoration: const InputDecoration(
                  labelText: '服务地址',
                  hintText: 'https://你的服务地址',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: '个人访问码'),
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, [address.text.trim(), code.text.trim()]),
            child: const Text('连接'),
          ),
        ],
      ),
    );
    // 对话框退出动画期间输入框仍会读取控制器，由框架回收页面后再释放。
    await Future<void>.delayed(const Duration(milliseconds: 300));
    address.dispose();
    code.dispose();
    if (settings == null || !mounted) return;
    final previousEndpoint = AssistantApi.endpoint,
        previousCode = AssistantApi.accessCode;
    AssistantApi.endpoint = settings[0];
    AssistantApi.accessCode = settings[1];
    try {
      final health = await _api.request('GET', '/v1/health');
      if (health['service'] != 'examhub-assistant') {
        throw Exception('地址不是考试通备考服务。');
      }
      await _store.write('connection', {'endpoint': AssistantApi.endpoint});
      if (mounted) setState(() => _error = null);
      if (_job != null) _resume();
    } catch (e) {
      AssistantApi.endpoint = previousEndpoint;
      AssistantApi.accessCode = previousCode;
      if (mounted) setState(() => _error = _friendly(e));
    }
  }

  Future<void> _start() async {
    if (!_form.currentState!.validate()) return;
    final now = DateTime.now();
    if (_date == null ||
        !_date!.isAfter(DateTime(now.year, now.month, now.day))) {
      setState(() => _error = '请选择未来的个人复习截止日。');
      return;
    }
    if (_studyDays.isEmpty) {
      setState(() => _error = '请选择每周至少一个学习日。'); return;
    }
    if (AssistantApi.accessCode.isEmpty && widget.api == null) {
      await _connect();
      if (AssistantApi.accessCode.isEmpty || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = '正在提交备考目标';
    });
    final goal = <String, dynamic>{
      'exam': _exam.text.trim(),
      'region': _region.text.trim(),
      'level': _level.text.trim(),
      'preferences': _preferences.text.trim(),
      'targetDate': _day(_date!),
      'minutes': int.parse(_minutes.text),
      'studyDays': _studyDays.toList()..sort(),
    };
    try {
      final reply = await _api.request('POST', '/v1/research', goal);
      _job = reply['id'] as String;
      _document = {
        'goal': goal,
        'job': _job,
        'jobEndpoint': AssistantApi.endpoint,
      };
      await _save();
      if (mounted) _resume();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _friendly(e);
        });
      }
    }
  }

  void _resume() {
    if (!mounted || _job == null) return;
    if (_document?['jobEndpoint'] != AssistantApi.endpoint) {
      setState(() {
        _busy = false;
        _error = '请连接创建该研究任务时使用的服务地址。';
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = '正在核对考试、大纲与题库，通常需要几分钟';
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    if (_polling || _job == null) return;
    _polling = true;
    final currentJob = _job;
    try {
      final reply = await _api.request('GET', '/v1/research/$_job');
      if (!mounted || _job != currentJob) return;
      if (reply['status'] == 'completed') {
        _timer?.cancel();
        _document!['result'] = reply['result'];
        _document!.remove('job');
        _job = null;
        await _save();
        if (mounted) {
          setState(() {
            _busy = false;
            _week = 0;
            _error = null;
            _message = '研究已保存，可以开始复习';
          });
        }
      } else if (['failed', 'cancelled'].contains(reply['status'])) {
        _timer?.cancel();
        _document!.remove('job');
        _job = null;
        await _save();
        if (mounted) {
          setState(() {
            _busy = false;
            _error = reply['message'] as String? ?? '研究未完成，请重试。';
          });
        }
      } else {
        setState(() => _message = reply['message'] as String? ?? '正在研究');
      }
    } catch (e) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '${_friendly(e)} 已保留任务，可连接后继续查看。';
        });
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _cancel() async {
    try {
      await _api.request('DELETE', '/v1/research/$_job');
      _timer?.cancel();
      _job = null;
      _document!.remove('job');
      await _save();
      if (mounted) {
        setState(() {
          _busy = false;
          _message = '已停止研究';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    }
  }

  Future<void> _done(Map<String, dynamic> task, bool value) async {
    final before = task['done'];
    setState(() => task['done'] = value);
    try {
      await _save();
    } catch (_) {
      if (mounted) {
        setState(() {
          task['done'] = before;
          _error = '进度未保存，请重试。';
        });
      }
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int max = 120,
    bool required = false,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c,
      maxLength: max,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
      validator: (value) =>
          required && (value?.trim().isEmpty ?? true) ? '请填写$label' : null,
    ),
  );

  Widget _goalForm() => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('先确定你的备考目标', style: AppTheme.heading3),
        const SizedBox(height: 8),
        const Text(
          '不在考试库里也可以。写清正式名称、级别或科目，能找到更合适的资料。',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _field(_exam, '想考什么', required: true, hint: '例如：计算机二级 Python'),
        _field(_region, '报考地区', max: 80, hint: '例如：上海；不确定可留空'),
        _field(_level, '目前基础与薄弱点', max: 160, hint: '例如：学过基础，但程序设计薄弱'),
        _field(_preferences, '资料偏好', max: 600, hint: '例如：免费优先，需要解析，可导入掌心刷题'),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final first = DateTime(now.year, now.month, now.day + 1);
            final last = DateTime(now.year, now.month, now.day + 730);
            final initial =
                _date != null &&
                    !_date!.isBefore(first) &&
                    !_date!.isAfter(last)
                ? _date!
                : first.add(const Duration(days: 59));
            final date = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: first,
              lastDate: last,
            );
            if (date != null && mounted) setState(() => _date = date);
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(_date == null ? '选择个人复习截止日' : '复习到 ${_day(_date!)}'),
        ),
        const SizedBox(height: 6),
        const Text('这是你希望准备好的日期，助手会另行查证正式考试安排。', style: AppTheme.bodySmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _minutes,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '每个学习日可用时间',
            suffixText: '分钟',
          ),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 15 || n > 480 ? '请填写 15 至 480 分钟' : null;
          },
        ),
        const SizedBox(height: 18),
        const Text('每周哪些天可以学习？'),
        Wrap(spacing: 6, children: [
          for (var day = 1; day <= 7; day++) FilterChip(
            label: Text(['周一', '周二', '周三', '周四', '周五', '周六', '周日'][day - 1]),
            selected: _studyDays.contains(day),
            onSelected: (selected) => setState(() { if (selected) { _studyDays.add(day); } else { _studyDays.remove(day); } }),
          ),
        ]),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy || !_ready || _job != null ? null : _start,
          icon: const Icon(Icons.travel_explore),
          label: const Text('检索资料并规划复习'),
        ),
      ],
    ),
  );

  Widget _results() {
    final result = _result!;
    final plan = result['plan'] as Map<String, dynamic>;
    final tasks = (plan['tasks'] as List).cast<Map<String, dynamic>>();
    final dates = tasks.map((t) => t['date'] as String).toSet().toList()
      ..sort();
    final shown = dates.skip(_week * 7).take(7).toSet();
    final completed = tasks.where((t) => t['done'] == true).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_document!['goal']['exam'] as String, style: AppTheme.heading3),
        const SizedBox(height: 8),
        Text(result['summary'] as String),
        const SizedBox(height: 10),
        Text(
          '检索于 ${result['searchedAt']}，共 ${result['searches']} 次检索。来源类型和题库适配由 AI 整理，使用前请核对原文。',
          style: AppTheme.bodySmall,
        ),
        for (final item in result['uncertainties'] as List)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '待确认：$item',
              style: const TextStyle(color: AppTheme.warningColor),
            ),
          ),
        const SizedBox(height: 22),
        const Text('考试依据', style: AppTheme.heading3),
        if ((result['sources'] as List).isEmpty)
          const Text('没有找到足够可靠的来源，先确认考试正式名称和主办方。'),
        for (final source in result['sources'] as List)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(source['title'] as String),
            subtitle: Text(
              source['kind'] == 'official' ? 'AI 判断为官方来源，待核对' : '资料来源，待核对',
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(source['finding'] as String),
              ),
              TextButton(
                onPressed: () =>
                    ExternalActions.open(context, source['url'] as String),
                child: const Text('打开原文核对'),
              ),
            ],
          ),
        const SizedBox(height: 22),
        const Text('适合的题库候选', style: AppTheme.heading3),
        if ((result['banks'] as List).isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('暂未找到足够匹配的题库。可以补充科目、地区或版本后重新检索。'),
          ),
        for (final bank in result['banks'] as List)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(bank['name'] as String),
            subtitle: Text(bank['fit'] as String),
            children: [
              for (final entry in {
                '版本': 'version',
                '费用': 'cost',
                '局限': 'limitations',
                '导入条件': 'importability',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${entry.key}：${bank[entry.value]}'),
                  ),
                ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () =>
                        ExternalActions.open(context, bank['url'] as String),
                    child: const Text('查看题库原页'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text:
                              '考试：${_document!['goal']['exam']}\n题库候选：${bank['name']}\n来源：${bank['url']}\n版本：${bank['version']}\n导入条件：${bank['importability']}\n请先核对授权与内容，再下载资料导入；此链接并非题库文件。',
                        ),
                      );
                      if (!mounted) return;
                      await ExternalActions.practice(context);
                    },
                    child: const Text('复制资料并打开掌心刷题'),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '不会自动购买或导入网页。请确认授权后，在掌心刷题选择题库或导入资料。',
                  style: AppTheme.bodySmall,
                ),
              ),
            ],
          ),
        const SizedBox(height: 22),
        const Text('每日复习任务', style: AppTheme.heading3),
        const SizedBox(height: 8),
        Text(
          '${plan['days']} 个学习日，每天 ${_document!['goal']['minutes']} 分钟；已完成 $completed / ${tasks.length} 项',
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: tasks.isEmpty ? 0 : completed / tasks.length,
        ),
        const SizedBox(height: 12),
        Text(plan['notice'] as String, style: AppTheme.bodySmall),
        for (final date in shown) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6),
            child: Text(date, style: AppTheme.heading3),
          ),
          for (final task in tasks.where((t) => t['date'] == date))
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: task['done'] == true,
              onChanged: (value) => _done(task, value ?? false),
              title: Text(task['title'] as String),
              subtitle: Text('${task['subject']}，${task['minutes']} 分钟'),
            ),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _week > 0 ? () => setState(() => _week--) : null,
              child: const Text('上一周'),
            ),
            Text('第 ${_week + 1} 周'),
            TextButton(
              onPressed: (_week + 1) * 7 < dates.length
                  ? () => setState(() => _week++)
                  : null,
              child: const Text('下一周'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('备考助手'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _connect,
          tooltip: '连接备考服务',
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: !_ready
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              const Text(
                '想考什么，\n我们从这里开始。',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text('查官方信息，找合适题库，把复习安排进每一天。', style: AppTheme.bodySmall),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_message),
                ),
              if (_busy) ...[
                const LinearProgressIndicator(),
                TextButton(onPressed: _cancel, child: const Text('停止本次研究')),
              ],
              if (!_busy && _job != null)
                Wrap(
                  children: [
                    TextButton(
                      onPressed: _connect,
                      child: const Text('连接并继续查看'),
                    ),
                    TextButton(
                      onPressed: () async {
                        _timer?.cancel();
                        _job = null;
                        _document?.remove('job');
                        await _save();
                        if (mounted) {
                          setState(() {
                            _busy = false;
                            _error = null;
                            _message = '已放弃本地任务记录，服务端研究会在超时后停止';
                          });
                        }
                      },
                      child: const Text('放弃任务记录'),
                    ),
                  ],
                ),
              if (_result != null) ...[
                _results(),
                const Divider(height: 48),
                const Text(
                  '调整目标后重新研究会生成新计划。当前计划的打卡进度不会带入新计划。',
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              if (!_busy && _job == null) _goalForm(),
            ],
          ),
  );
}
