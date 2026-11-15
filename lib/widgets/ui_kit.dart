import 'package:material_ui/material_ui.dart';

import '../models/exam.dart';
import '../theme/app_theme.dart';

String shortDate(DateTime value) =>
    '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 34,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          top: 6,
          child: Container(
            width: 22,
            height: 26,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        Positioned(
          left: 6,
          top: 0,
          child: Container(
            width: 23,
            height: 27,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ],
    ),
  );
}

class PageHeading extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const PageHeading(this.title, this.subtitle, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.heading1),
              const SizedBox(height: 8),
              Text(subtitle, style: AppTheme.bodySmall),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionHeading(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 12, 12),
    child: Row(
      children: [
        Expanded(child: Text(title, style: AppTheme.heading2)),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class StatePill extends StatelessWidget {
  final String label;
  final bool verified;
  const StatePill(this.label, {super.key, this.verified = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: verified ? const Color(0xFFE9F6F1) : AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: verified ? AppTheme.successColor : AppTheme.primaryColor,
      ),
    ),
  );
}

class ExamRow extends StatelessWidget {
  final Exam exam;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool bookmarked;
  const ExamRow({
    super.key,
    required this.exam,
    required this.onTap,
    this.onBookmark,
    this.bookmarked = false,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 43,
              height: 49,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppTheme.primaryColor, width: 3),
                ),
              ),
              child: Text(
                String.fromCharCodes(exam.name.runes.take(2)),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.name,
                    style: AppTheme.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    exam.isCustom ? '个人添加 · ${exam.industry}' : exam.industry,
                    style: AppTheme.bodySmall,
                  ),
                  if (exam.targetDate != null)
                    Text(
                      '我的目标日 ${shortDate(exam.targetDate!)}',
                      style: AppTheme.caption,
                    ),
                ],
              ),
            ),
            if (onBookmark != null)
              IconButton(
                tooltip: bookmarked ? '取消收藏' : '收藏考试',
                onPressed: onBookmark,
                icon: Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: bookmarked
                      ? AppTheme.primaryColor
                      : AppTheme.textLight,
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textLight,
              ),
          ],
        ),
      ),
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  final String title, message, action;
  final VoidCallback onTap;
  final IconData icon;
  const EmptyPanel({
    super.key,
    required this.title,
    required this.message,
    required this.action,
    required this.onTap,
    this.icon = Icons.add_task_rounded,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 14),
        Text(title, style: AppTheme.heading3),
        const SizedBox(height: 7),
        Text(message, style: AppTheme.bodySmall),
        const SizedBox(height: 15),
        OutlinedButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}
