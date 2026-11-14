import 'package:material_ui/material_ui.dart';

import '../database/database_helper.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'exam_detail_screen.dart';

Future<void> openCustomExam(
  BuildContext context, {
  String initialName = '',
}) async {
  final id = await Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (_) => CustomExamScreen(initialName: initialName),
    ),
  );
  if (id != null && context.mounted) {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ExamDetailScreen(examId: id)));
  }
}

class CustomExamScreen extends StatefulWidget {
  final String initialName;
  final Exam? existing;
  const CustomExamScreen({super.key, this.initialName = '', this.existing});
  @override
  State<CustomExamScreen> createState() => _CustomExamScreenState();
}

class _CustomExamScreenState extends State<CustomExamScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _industry = TextEditingController();
  final _website = TextEditingController();
  DateTime? _target;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? widget.initialName);
    _industry.text = widget.existing?.industry ?? '';
    _website.text = widget.existing?.officialWebsite ?? '';
    _target = widget.existing?.targetDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _industry.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final int id;
      if (widget.existing == null) {
        id = await DatabaseHelper().addCustomExam(name: _name.text, industry: _industry.text, officialWebsite: _website.text, targetDate: _target);
      } else {
        id = widget.existing!.id;
        await DatabaseHelper().updateCustomExam(id: id, name: _name.text, industry: _industry.text, officialWebsite: _website.text, targetDate: _target);
      }
      if (mounted) Navigator.pop(context, id);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is ArgumentError ? error.message.toString() : '保存未完成，请检查填写内容后重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.existing == null ? '添加自己的考试' : '编辑个人考试')),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('考试不在目录里，\n也可以开始准备。', style: AppTheme.heading1),
            const SizedBox(height: 12),
            const Text(
              '添加后会加入我的关注，资料由你填写。找到同名考试时会直接使用已有档案。',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '考试名称',
                hintText: '例如：大学英语六级、单位招聘考试',
              ),
              maxLength: 100,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请填写考试名称' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _industry,
              decoration: const InputDecoration(
                labelText: '行业或方向（选填）',
                hintText: '例如：外语、升学、职业技能',
              ),
              maxLength: 60,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _website,
              decoration: const InputDecoration(
                labelText: '官方信息网址（选填）',
                hintText: 'https://',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final uri = Uri.tryParse(value.trim());
                return uri != null &&
                        ['https', 'http'].contains(uri.scheme) &&
                        uri.host.isNotEmpty
                    ? null
                    : '请填写完整的 http 或 https 网址';
              },
            ),
            const SizedBox(height: 24),
            const Text('我的目标日期', style: AppTheme.heading3),
            const SizedBox(height: 6),
            const Text('用于个人备考规划，不作为官方考试日期。', style: AppTheme.bodySmall),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: _target ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 6),
                );
                if (date != null && mounted) setState(() => _target = date);
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _target == null ? '选择日期（可稍后填写）' : shortDate(_target!),
              ),
            ),
            if (_target != null)
              TextButton(
                onPressed: () => setState(() => _target = null),
                child: const Text('清除目标日期'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB3261E)),
                ),
              ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '正在保存…' : widget.existing == null ? '添加并关注' : '保存修改'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
