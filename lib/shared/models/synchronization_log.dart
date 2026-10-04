class SynchronizationLog {
  final int id;
  final DateTime startedAt;
  final DateTime completedAt;
  final String status; // 'SUCCESS', 'PARTIAL', 'FAILED'
  final int recordsFound;
  final int recordsInserted;
  final int recordsUpdated;
  final int recordsSkipped;
  final String? errorMessage;
  final String sourceUrl;

  SynchronizationLog({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.status,
    required this.recordsFound,
    required this.recordsInserted,
    required this.recordsUpdated,
    required this.recordsSkipped,
    this.errorMessage,
    required this.sourceUrl,
  });

  factory SynchronizationLog.fromMap(Map<String, dynamic> map) {
    return SynchronizationLog(
      id: map['id'] as int,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: DateTime.parse(map['completed_at'] as String),
      status: map['status'] as String,
      recordsFound: map['records_found'] as int? ?? 0,
      recordsInserted: map['records_inserted'] as int? ?? 0,
      recordsUpdated: map['records_updated'] as int? ?? 0,
      recordsSkipped: map['records_skipped'] as int? ?? 0,
      errorMessage: map['error_message'] as String?,
      sourceUrl: map['source_url'] as String? ?? 'https://www.pcso.gov.ph/searchlottoresult.aspx',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'status': status,
      'records_found': recordsFound,
      'records_inserted': recordsInserted,
      'records_updated': recordsUpdated,
      'records_skipped': recordsSkipped,
      'error_message': errorMessage,
      'source_url': sourceUrl,
    };
  }
}
