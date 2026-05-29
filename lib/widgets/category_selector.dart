import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 横向滚动分类选择器
class CategorySelector extends StatelessWidget {
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onSelected;
  final String? label;

  const CategorySelector({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onSelected,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(
                left: AppTheme.spacingMd, bottom: AppTheme.spacingSm),
            child: Text(label!, style: AppTheme.heading3),
          ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item == selectedItem;
              return GestureDetector(
                onTap: () => onSelected(item),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 多选标签组
class TagGroup extends StatelessWidget {
  final String label;
  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<Set<String>> onChanged;

  const TagGroup({
    super.key,
    required this.label,
    required this.tags,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppTheme.spacingMd, bottom: AppTheme.spacingSm),
          child: Text(label, style: AppTheme.bodySmall),
        ),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            itemCount: tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = tags[index];
              final isSelected = selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  final newSet = Set<String>.from(selectedTags);
                  if (isSelected) {
                    newSet.remove(tag);
                  } else {
                    newSet.add(tag);
                  }
                  onChanged(newSet);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.check,
                              size: 14, color: AppTheme.primaryColor),
                        ),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
