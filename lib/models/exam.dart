/// 考试核心数据模型
class Exam {
  final int id;
  final String name; // 简称，如 "CPA"
  final String fullName; // 全称，如 "注册会计师全国统一考试"
  final String category; // 准入类/水平评价类/国际认证/企业认证/技能等级
  final String industry; // 财会/法律/建筑/医疗/教育/IT/公共管理
  final List<String> targetGroups; // ["在校生","应届","职场1-3年","职场3-5年+"]
  final String organizingBody; // 主办单位
  final String officialWebsite; // 官网URL
  final int difficulty; // 1-5星难度
  final double goldContent; // 含金量评分(社区驱动)
  final String description; // 简介
  final String eligibility; // 报名条件摘要
  final String examFormat; // 考试形式
  final List<ExamSubject> subjects; // 考试科目
  final List<String> tags; // 补充标签
  final String? logoAssetPath; // logo资源路径

  const Exam({
    required this.id,
    required this.name,
    required this.fullName,
    required this.category,
    required this.industry,
    required this.targetGroups,
    required this.organizingBody,
    required this.officialWebsite,
    required this.difficulty,
    required this.goldContent,
    required this.description,
    required this.eligibility,
    required this.examFormat,
    required this.subjects,
    required this.tags,
    this.logoAssetPath,
  });

  /// 从数据库Map创建
  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int,
      name: map['name'] as String,
      fullName: map['full_name'] as String,
      category: map['category'] as String,
      industry: map['industry'] as String,
      targetGroups: _parseList(map['target_groups']),
      organizingBody: map['organizing_body'] as String,
      officialWebsite: map['official_website'] as String,
      difficulty: map['difficulty'] as int,
      goldContent: (map['gold_content'] as num).toDouble(),
      description: map['description'] as String,
      eligibility: map['eligibility'] as String,
      examFormat: map['exam_format'] as String? ?? '',
      subjects: ExamSubject.fromJsonList(map['subjects']),
      tags: _parseList(map['tags']),
    );
  }

  /// 转为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'full_name': fullName,
      'category': category,
      'industry': industry,
      'target_groups': _toJson(targetGroups),
      'organizing_body': organizingBody,
      'official_website': officialWebsite,
      'difficulty': difficulty,
      'gold_content': goldContent,
      'description': description,
      'eligibility': eligibility,
      'exam_format': examFormat,
      'subjects': _toJson(subjects.map((s) => s.toMap()).toList()),
      'tags': _toJson(tags),
    };
  }

  /// Exam对象转Map (兼容)
  Map<String, dynamic> toJson() => toMap();

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      try {
        final decoded = value;
        // 处理JSON字符串
        if (decoded.startsWith('[')) {
          return (RegExp(r'"([^"]*)"')
                  .allMatches(decoded)
                  .map((m) => m.group(1)!)
                  .toList());
        }
        return [decoded];
      } catch (_) {
        return [value.toString()];
      }
    }
    return [];
  }

  static String _toJson(dynamic value) {
    if (value is List) {
      return value.map((e) {
        if (e is String) return '"$e"';
        if (e is Map) return _mapToString(e);
        return e.toString();
      }).join(',');
    }
    return value.toString();
  }

  static String _mapToString(Map<String, dynamic> map) {
    final entries =
        map.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
    return '{$entries}';
  }

  /// 获取难度星级文本
  String get difficultyStars => '⭐' * difficulty;

  /// 获取含金量星级文本
  String get goldContentStars {
    final fullStars = goldContent.floor();
    final halfStar = (goldContent - fullStars) >= 0.5;
    return '⭐' * fullStars + (halfStar ? '✨' : '');
  }
}

/// 考试科目模型
class ExamSubject {
  final String name;
  final String format; // 笔试/机考/面试/实操
  final int duration; // 分钟

  const ExamSubject({
    required this.name,
    required this.format,
    required this.duration,
  });

  factory ExamSubject.fromMap(Map<String, dynamic> map) {
    return ExamSubject(
      name: map['name'] as String? ?? '',
      format: map['format'] as String? ?? '笔试',
      duration: map['duration'] as int? ?? 120,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'format': format,
        'duration': duration,
      };

  static List<ExamSubject> fromJsonList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => ExamSubject.fromMap(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    if (value is String && value.startsWith('[')) {
      // 尝试解析JSON字符串
      try {
        return _parseSubjectsString(value);
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  static List<ExamSubject> _parseSubjectsString(String json) {
    // 简化版JSON数组解析，避免依赖dart:convert在模型层的复杂性
    final result = <ExamSubject>[];
    final matches = RegExp(r'\{[^}]+\}').allMatches(json);
    for (final match in matches) {
      final obj = match.group(0)!;
      final nameMatch = RegExp(r'"name"\s*:\s*"([^"]*)"').firstMatch(obj);
      final formatMatch = RegExp(r'"format"\s*:\s*"([^"]*)"').firstMatch(obj);
      final durMatch = RegExp(r'"duration"\s*:\s*(\d+)').firstMatch(obj);
      if (nameMatch != null) {
        result.add(ExamSubject(
          name: nameMatch.group(1)!,
          format: formatMatch?.group(1) ?? '笔试',
          duration: int.tryParse(durMatch?.group(1) ?? '120') ?? 120,
        ));
      }
    }
    return result;
  }
}
