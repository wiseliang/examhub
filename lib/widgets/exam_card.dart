import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';

/// 考试信息卡片 - 内容丰富型，类似小红书笔记卡片
class ExamCard extends StatelessWidget {
  final Exam exam;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  const ExamCard({
    super.key,
    required this.exam,
    this.onTap,
    this.onBookmark,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final industryColor = AppTheme.getIndustryColor(exam.industry);
    final categoryColor = AppTheme.getCategoryColor(exam.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部色条 + 基本信息
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: industryColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLg),
                  topRight: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧图标区
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: industryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        exam.name.length > 3
                            ? exam.name.substring(0, 3)
                            : exam.name,
                        style: TextStyle(
                          fontSize: exam.name.length > 3 ? 10 : 14,
                          fontWeight: FontWeight.bold,
                          color: industryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),

                  // 中间标题区
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exam.fullName,
                          style: AppTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // 星级
                        Row(
                          children: [
                            _buildStars(exam.goldContent, color: AppTheme.accentColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${exam.goldContent}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.signal_cellular_alt,
                                size: 14, color: AppTheme.textLight),
                            const SizedBox(width: 2),
                            Text(
                              '难度${exam.difficulty}/5',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 右侧收藏按钮
                  GestureDetector(
                    onTap: onBookmark,
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? AppTheme.accentColor
                          : AppTheme.textLight,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // 标签行
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingSm,
                AppTheme.spacingMd,
                0,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildTag(exam.category, categoryColor),
                  _buildTag(exam.industry, industryColor),
                  if (exam.targetGroups.isNotEmpty)
                    _buildTag(exam.targetGroups.first, AppTheme.primaryColor),
                  if (exam.tags.isNotEmpty)
                    _buildTag(exam.tags.first, AppTheme.textSecondary),
                ],
              ),
            ),

            // 简介
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingSm,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
              ),
              child: Text(
                exam.description,
                style: AppTheme.bodySmall.copyWith(height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStars(double rating,
      {Color color = AppTheme.accentColor, double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: size, color: color);
        } else if (index < rating && rating % 1 >= 0.5) {
          return Icon(Icons.star_half, size: size, color: color);
        }
        return Icon(Icons.star_border, size: size, color: AppTheme.textLight);
      }),
    );
  }
}

/// 紧凑型考试卡片 - 用于列表/搜索结果
class ExamCardCompact extends StatelessWidget {
  final Exam exam;
  final VoidCallback? onTap;

  const ExamCardCompact({super.key, required this.exam, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm + 4,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.cardColor,
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(exam.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          )),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          exam.goldContent.floor(),
                          (_) => const Icon(Icons.star,
                              size: 13, color: AppTheme.accentColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(exam.organizingBody,
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
