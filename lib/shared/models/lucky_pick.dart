class LuckyPick {
  final int id;
  final int userId;
  final int lottoTypeId;
  final String drawDate; // yyyy-MM-dd
  final int number1;
  final int number2;
  final int number3;
  final int number4;
  final int number5;
  final int number6;
  final DateTime generatedAt;
  final bool isChecked;
  final int matchCount;
  final String status; // 'PENDING', 'NOT_WINNING', 'PARTIAL_MATCH', 'WINNER'
  final String? lottoTypeName;
  final String? lottoTypeCode;

  LuckyPick({
    required this.id,
    required this.userId,
    required this.lottoTypeId,
    required this.drawDate,
    required this.number1,
    required this.number2,
    required this.number3,
    required this.number4,
    required this.number5,
    required this.number6,
    required this.generatedAt,
    this.isChecked = false,
    this.matchCount = 0,
    this.status = 'PENDING',
    this.lottoTypeName,
    this.lottoTypeCode,
  });

  List<int> get numbers => [number1, number2, number3, number4, number5, number6];

  LuckyPick copyWith({
    bool? isChecked,
    int? matchCount,
    String? status,
  }) {
    return LuckyPick(
      id: id,
      userId: userId,
      lottoTypeId: lottoTypeId,
      drawDate: drawDate,
      number1: number1,
      number2: number2,
      number3: number3,
      number4: number4,
      number5: number5,
      number6: number6,
      generatedAt: generatedAt,
      isChecked: isChecked ?? this.isChecked,
      matchCount: matchCount ?? this.matchCount,
      status: status ?? this.status,
      lottoTypeName: lottoTypeName,
      lottoTypeCode: lottoTypeCode,
    );
  }

  factory LuckyPick.fromMap(Map<String, dynamic> map) {
    return LuckyPick(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      lottoTypeId: map['lotto_type_id'] as int,
      drawDate: map['draw_date'] as String,
      number1: map['number_1'] as int,
      number2: map['number_2'] as int,
      number3: map['number_3'] as int,
      number4: map['number_4'] as int,
      number5: map['number_5'] as int,
      number6: map['number_6'] as int,
      generatedAt: DateTime.parse(map['generated_at'] as String),
      isChecked: (map['is_checked'] as int) == 1,
      matchCount: map['match_count'] as int? ?? 0,
      status: map['status'] as String? ?? 'PENDING',
      lottoTypeName: map['lotto_type_name'] as String?,
      lottoTypeCode: map['lotto_type_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'lotto_type_id': lottoTypeId,
      'draw_date': drawDate,
      'number_1': number1,
      'number_2': number2,
      'number_3': number3,
      'number_4': number4,
      'number_5': number5,
      'number_6': number6,
      'generated_at': generatedAt.toIso8601String(),
      'is_checked': isChecked ? 1 : 0,
      'match_count': matchCount,
      'status': status,
    };
  }
}
