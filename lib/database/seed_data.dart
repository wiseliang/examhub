import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

/// 种子数据管理 - 从assets JSON加载初始考试数据
class SeedData {
  static const String _seedFile = 'assets/seed_exams.json';

  /// 将种子数据插入数据库
  static Future<void> insertAll(Database db) async {
    final exams = await _loadExams();
    final batch = db.batch();

    for (final exam in exams) {
      // 处理subjects：确保是JSON字符串
      final subjects = exam['subjects'];
      final subjectsJson = subjects is String ? subjects : jsonEncode(subjects ?? []);

      // 处理target_groups
      final targetGroups = exam['target_groups'];
      final targetGroupsJson = targetGroups is String
          ? targetGroups
          : jsonEncode(targetGroups ?? []);

      // 处理tags
      final tags = exam['tags'];
      final tagsJson = tags is String ? tags : jsonEncode(tags ?? []);

      batch.insert('exam', {
        'id': exam['id'],
        'name': exam['name'],
        'full_name': exam['full_name'],
        'category': exam['category'],
        'industry': exam['industry'],
        'target_groups': targetGroupsJson,
        'organizing_body': exam['organizing_body'],
        'official_website': exam['official_website'],
        'difficulty': exam['difficulty'],
        'gold_content': exam['gold_content'],
        'description': exam['description'],
        'eligibility': exam['eligibility'],
        'exam_format': exam['exam_format'] ?? '',
        'subjects': subjectsJson,
        'tags': tagsJson,
      });

      // 插入时间线
      final timelines = exam['timelines'] as List<dynamic>?;
      if (timelines != null) {
        for (final tl in timelines) {
          batch.insert('exam_timeline', {
            'exam_id': exam['id'],
            'event_type': tl['event_type'],
            'period_desc': tl['period_desc'],
            'date': tl['date'] as String?,
            'is_estimated': tl['is_estimated'] == true ? 1 : 0,
            'source_url': tl['source_url'] as String?,
          });
        }
      }
    }

    await batch.commit(noResult: true);
  }

  /// 从assets加载种子数据
  static Future<List<Map<String, dynamic>>> _loadExams() async {
    final String jsonString = await rootBundle.loadString(_seedFile);
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> examList = data['exams'];
    return examList.cast<Map<String, dynamic>>();
  }
}
