class LottoType {
  final int id;
  final String code;
  final String name;
  final int minNumber;
  final int maxNumber;
  final int numberCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LottoType({
    required this.id,
    required this.code,
    required this.name,
    this.minNumber = 1,
    required this.maxNumber,
    this.numberCount = 6,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Range description, e.g. "1-58"
  String get rangeDescription => '$minNumber–$maxNumber';

  factory LottoType.fromMap(Map<String, dynamic> map) {
    return LottoType(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      minNumber: map['min_number'] as int? ?? 1,
      maxNumber: map['max_number'] as int,
      numberCount: map['number_count'] as int? ?? 6,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'min_number': minNumber,
      'max_number': maxNumber,
      'number_count': numberCount,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
