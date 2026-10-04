import 'dart:convert';

class PredictionHistory {
  final int id;
  final int lottoTypeId;
  final String predictionDate;
  final String analysisStartDate;
  final String analysisEndDate;
  final String algorithm;
  final List<int> predictedNumbers;
  final double confidenceScore;
  final String analysisSummary;
  final DateTime createdAt;
  final String? lottoTypeName;

  PredictionHistory({
    required this.id,
    required this.lottoTypeId,
    required this.predictionDate,
    required this.analysisStartDate,
    required this.analysisEndDate,
    required this.algorithm,
    required this.predictedNumbers,
    required this.confidenceScore,
    required this.analysisSummary,
    required this.createdAt,
    this.lottoTypeName,
  });

  factory PredictionHistory.fromMap(Map<String, dynamic> map) {
    List<int> numbers = [];
    final rawNumbers = map['predicted_numbers'];
    if (rawNumbers is String) {
      try {
        final decoded = jsonDecode(rawNumbers);
        if (decoded is List) {
          numbers = decoded.map((e) => e as int).toList();
        }
      } catch (_) {
        numbers = rawNumbers.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      }
    }
    return PredictionHistory(
      id: map['id'] as int,
      lottoTypeId: map['lotto_type_id'] as int,
      predictionDate: map['prediction_date'] as String,
      analysisStartDate: map['analysis_start_date'] as String,
      analysisEndDate: map['analysis_end_date'] as String,
      algorithm: map['algorithm'] as String,
      predictedNumbers: numbers,
      confidenceScore: (map['confidence_score'] as num).toDouble(),
      analysisSummary: map['analysis_summary'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      lottoTypeName: map['lotto_type_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lotto_type_id': lottoTypeId,
      'prediction_date': predictionDate,
      'analysis_start_date': analysisStartDate,
      'analysis_end_date': analysisEndDate,
      'algorithm': algorithm,
      'predicted_numbers': jsonEncode(predictedNumbers),
      'confidence_score': confidenceScore,
      'analysis_summary': analysisSummary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
