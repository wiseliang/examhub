/// 考试时间节点模型
class ExamTimeline {
  final int? id;
  final int examId;
  final String eventType; // 报名开始/报名截止/准考证打印/考试/出成绩
  final String periodDesc; // "每年6月" 或 "上半年/下半年"
  final DateTime? date; // 具体日期(如已知)
  final bool isEstimated; // 是否预估
  final String? sourceUrl;

  const ExamTimeline({
    this.id,
    required this.examId,
    required this.eventType,
    required this.periodDesc,
    this.date,
    this.isEstimated = true,
    this.sourceUrl,
  });

  factory ExamTimeline.fromMap(Map<String, dynamic> map) {
    return ExamTimeline(
      id: map['id'] as int?,
      examId: map['exam_id'] as int,
      eventType: map['event_type'] as String,
      periodDesc: map['period_desc'] as String,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      isEstimated: map['is_estimated'] == 1 || map['is_estimated'] == true,
      sourceUrl: map['source_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exam_id': examId,
      'event_type': eventType,
      'period_desc': periodDesc,
      'date': date?.toIso8601String(),
      'is_estimated': isEstimated ? 1 : 0,
      'source_url': sourceUrl,
    };
  }

  /// 事件类型中文名
  String get eventTypeLabel {
    switch (eventType) {
      case 'signup_start':
        return '报名开始';
      case 'signup_end':
        return '报名截止';
      case 'admit_card':
        return '准考证打印';
      case 'exam':
        return '考试';
      case 'score':
        return '成绩公布';
      default:
        return eventType;
    }
  }

  /// 事件类型图标
  String get eventIcon {
    switch (eventType) {
      case 'signup_start':
        return '📝';
      case 'signup_end':
        return '⏰';
      case 'admit_card':
        return '🎫';
      case 'exam':
        return '📖';
      case 'score':
        return '📊';
      default:
        return '📌';
    }
  }

  /// 离今天还有多少天（预估）
  int daysUntil(DateTime from) {
    if (date == null) return -1;
    return date!.difference(from).inDays;
  }
}

/// 官方通知模型
class ExamNotice {
  final int? id;
  final int examId;
  final String title;
  final DateTime publishDate;
  final String summary; // AI摘要
  final List<NoticeKeyPoint> keyPoints;
  final String sourceUrl;
  final DateTime? fetchedAt;

  const ExamNotice({
    this.id,
    required this.examId,
    required this.title,
    required this.publishDate,
    required this.summary,
    required this.keyPoints,
    required this.sourceUrl,
    this.fetchedAt,
  });

  factory ExamNotice.fromMap(Map<String, dynamic> map) {
    return ExamNotice(
      id: map['id'] as int?,
      examId: map['exam_id'] as int,
      title: map['title'] as String,
      publishDate: DateTime.parse(map['publish_date'] as String),
      summary: map['summary'] as String? ?? '',
      keyPoints: NoticeKeyPoint.fromJsonList(map['key_points']),
      sourceUrl: map['source_url'] as String? ?? '',
      fetchedAt: map['fetched_at'] != null
          ? DateTime.parse(map['fetched_at'] as String)
          : null,
    );
  }
}

/// 通知中的关键信息点
class NoticeKeyPoint {
  final String type; // 时间变更/条件变更/大纲调整/其他
  final String content;

  const NoticeKeyPoint({required this.type, required this.content});

  factory NoticeKeyPoint.fromMap(Map<String, dynamic> map) {
    return NoticeKeyPoint(
      type: map['type'] as String? ?? '其他',
      content: map['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'type': type, 'content': content};

  static List<NoticeKeyPoint> fromJsonList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) =>
              NoticeKeyPoint.fromMap(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return [];
  }
}
