import 'package:intl/intl.dart';

class LottoResult {
  final int id;
  final int lottoTypeId;
  final String drawDate; // yyyy-MM-dd
  final int number1;
  final int number2;
  final int number3;
  final int number4;
  final int number5;
  final int number6;
  final double jackpotPrize;
  final String source;
  final String sourceUrl;
  final DateTime scrapedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lottoTypeName;

  LottoResult({
    required this.id,
    required this.lottoTypeId,
    required this.drawDate,
    required this.number1,
    required this.number2,
    required this.number3,
    required this.number4,
    required this.number5,
    required this.number6,
    required this.jackpotPrize,
    this.source = 'PCSO',
    this.sourceUrl = 'https://www.pcso.gov.ph/searchlottoresult.aspx',
    required this.scrapedAt,
    required this.createdAt,
    required this.updatedAt,
    this.lottoTypeName,
  });

  List<int> get numbers => [number1, number2, number3, number4, number5, number6];

  String get formattedJackpot {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
    return formatter.format(jackpotPrize);
  }

  factory LottoResult.fromMap(Map<String, dynamic> map) {
    return LottoResult(
      id: map['id'] as int,
      lottoTypeId: map['lotto_type_id'] as int,
      drawDate: map['draw_date'] as String,
      number1: map['number_1'] as int,
      number2: map['number_2'] as int,
      number3: map['number_3'] as int,
      number4: map['number_4'] as int,
      number5: map['number_5'] as int,
      number6: map['number_6'] as int,
      jackpotPrize: (map['jackpot_prize'] as num).toDouble(),
      source: map['source'] as String? ?? 'PCSO',
      sourceUrl: map['source_url'] as String? ?? 'https://www.pcso.gov.ph/searchlottoresult.aspx',
      scrapedAt: DateTime.parse(map['scraped_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lottoTypeName: map['lotto_type_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lotto_type_id': lottoTypeId,
      'draw_date': drawDate,
      'number_1': number1,
      'number_2': number2,
      'number_3': number3,
      'number_4': number4,
      'number_5': number5,
      'number_6': number6,
      'jackpot_prize': jackpotPrize,
      'source': source,
      'source_url': sourceUrl,
      'scraped_at': scrapedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
