/// 某考试在某年、某地区、某级别的一次安排。
/// 旧数据没有年份时保持 null，不推算为今年。
class ExamSession {
  final int? id;
  final int examId;
  final int? year;
  final String region;
  final String level;
  final String batch;
  final String status;
  final String? sourceUrl;
  final DateTime? publishedAt;
  final DateTime? verifiedAt;

  const ExamSession({
    this.id,
    required this.examId,
    this.year,
    this.region = '未注明地区',
    this.level = '',
    this.batch = '',
    this.status = 'unpublished',
    this.sourceUrl,
    this.publishedAt,
    this.verifiedAt,
  });

  static const statuses = {
    'unpublished': '待公布',
    'estimated': '往年规律参考',
    'confirmed': '已核验',
    'postponed': '已延期',
    'cancelled': '已取消',
  };

  String get statusLabel => statuses[status] ?? '待核验';
  String get statusDescription => switch (status) {
    'estimated' => '往年资料仅供参考，不代表今年当地的确定安排。',
    'postponed' => '此安排已延期，请查看后续公告，不再按原日期规划。',
    'cancelled' => '此安排已取消，请核对官方公告。',
    'confirmed' => '日期已核验，后续变更仍以官方公告为准。',
    _ => '具体安排待官方公布，暂不提供确定日期。',
  };

  String get label => [
    year == null ? '年份待公布' : '$year 年',
    region,
    if (level.isNotEmpty) level,
    if (batch.isNotEmpty) batch,
  ].join(' · ');

  void validate() {
    if (!statuses.containsKey(status)) {
      throw ArgumentError('未知的安排状态');
    }
    if (year != null && (year! < 1900 || year! > 2200)) {
      throw ArgumentError('年份超出范围');
    }
    if (region.trim().isEmpty) throw ArgumentError('地区不能为空');
    if (status == 'confirmed') {
      final source = Uri.tryParse(sourceUrl ?? '');
      if (year == null ||
          verifiedAt == null ||
          source == null ||
          !['http', 'https'].contains(source.scheme) ||
          source.host.isEmpty) {
        throw ArgumentError('核验安排必须提供年份、来源和核验时间');
      }
    }
  }

  factory ExamSession.fromMap(Map<String, dynamic> map) => ExamSession(
    id: map['id'] as int?,
    examId: map['exam_id'] as int,
    year: map['year'] as int?,
    region: map['region'] as String,
    level: map['level'] as String,
    batch: map['batch'] as String,
    status: map['status'] as String,
    sourceUrl: map['source_url'] as String?,
    publishedAt: DateTime.tryParse(map['published_at'] as String? ?? ''),
    verifiedAt: DateTime.tryParse(map['verified_at'] as String? ?? ''),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'exam_id': examId,
    'year': year,
    'region': region,
    'level': level,
    'batch': batch,
    'status': status,
    'source_url': sourceUrl,
    'published_at': publishedAt?.toIso8601String(),
    'verified_at': verifiedAt?.toIso8601String(),
  };
}
