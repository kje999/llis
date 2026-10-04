import 'dart:math';
import '../../shared/models/lotto_result.dart';
import '../../shared/models/lotto_type.dart';
import '../analytics/domain/analytics_service.dart';

class StatisticalSuggestion {
  final int rank;
  final List<int> numbers;
  final double statisticalScore; // internal statistical ranking score
  final List<String> explanationPoints;

  StatisticalSuggestion({
    required this.rank,
    required this.numbers,
    required this.statisticalScore,
    required this.explanationPoints,
  });
}

class PredictionEngine {
  final AnalyticsService _analyticsService = AnalyticsService();

  /// Generates top N statistical suggestions based on 1-year historical dataset.
  List<StatisticalSuggestion> generateSuggestions({
    required LottoType lottoType,
    required List<LottoResult> historicalDraws,
    int count = 5,
  }) {
    final analytics = _analyticsService.analyze(
      lottoType: lottoType,
      draws: historicalDraws,
    );

    // If no data, generate safe distributed combinations
    if (analytics.totalDrawsAnalyzed < 5) {
      return _generateDefaultSuggestions(lottoType, count);
    }

    // Map each number (1..maxNumber) to an individual statistical weight
    final numberWeights = <int, double>{};
    final maxFreq = analytics.allFrequencies.map((f) => f.count).fold(1, max);

    for (final f in analytics.allFrequencies) {
      double weight = 10.0;

      // Frequency score (0-40)
      weight += (f.count / maxFreq) * 35.0;

      // Recency / Overdue balance (moderate gap is favored, extreme gap normalized)
      if (f.drawsSince >= 3 && f.drawsSince <= 15) {
        weight += 15.0; // active cycle
      } else if (f.drawsSince > 20) {
        weight += 10.0; // overdue interest
      } else {
        weight += 8.0; // drawn very recently
      }

      numberWeights[f.number] = weight;
    }

    // Top pairs for compatibility boost
    final topPairKeys = <String>{};
    for (final p in analytics.topPairs.take(5)) {
      topPairKeys.add('${p.number1}-${p.number2}');
    }

    // Generate candidate combinations and score them
    final candidates = <_CandidateCombination>[];
    final random = Random(1337); // Seeded for consistency within draw calculation

    // Sample candidate pools:
    // Blend of top hot numbers, balanced frequency, and overdue candidates
    final sortedNumbersByWeight = numberWeights.keys.toList()
      ..sort((a, b) => (numberWeights[b] ?? 0).compareTo(numberWeights[a] ?? 0));

    final midPoint = lottoType.maxNumber ~/ 2;

    // Generate 150 candidate combinations
    for (int iter = 0; iter < 150; iter++) {
      final selected = <int>{};

      // Select 2-3 from top weighted numbers
      final topPool = sortedNumbersByWeight.take(15).toList();
      while (selected.length < 3) {
        selected.add(topPool[random.nextInt(topPool.length)]);
      }

      // Fill remaining from full range to ensure diversity
      while (selected.length < 6) {
        final cand = sortedNumbersByWeight[random.nextInt(sortedNumbersByWeight.length)];
        selected.add(cand);
      }

      final combination = selected.toList()..sort();

      // Score combination
      double totalScore = 0.0;
      final explanations = <String>[];

      // 1. Base number scores
      double sumNumberWeights = 0.0;
      for (final n in combination) {
        sumNumberWeights += numberWeights[n] ?? 0.0;
      }
      totalScore += (sumNumberWeights / 6.0) * 0.6; // normalized base

      // 2. Odd/Even balance score
      int odd = 0;
      for (final n in combination) {
        if (n % 2 != 0) odd++;
      }
      if (odd == 3 || odd == 2 || odd == 4) {
        totalScore += 18.0;
        explanations.add('Balanced $odd Odd / ${6 - odd} Even distribution matching historical draw norms.');
      } else {
        totalScore += 5.0;
      }

      // 3. Low/High balance score
      int low = 0;
      for (final n in combination) {
        if (n <= midPoint) low++;
      }
      if (low >= 2 && low <= 4) {
        totalScore += 14.0;
        explanations.add('Well-distributed $low Low (1–$midPoint) and ${6 - low} High numbers.');
      } else {
        totalScore += 4.0;
      }

      // 4. Sum range compatibility
      final sum = combination.reduce((a, b) => a + b);
      final avg = analytics.sumStatistics.avgSum;
      final std = analytics.sumStatistics.standardDeviation;
      if (sum >= (avg - std) && sum <= (avg + std)) {
        totalScore += 15.0;
        explanations.add('Total sum of $sum falls squarely within the typical historical sum range (${analytics.sumStatistics.commonRange}).');
      } else {
        totalScore += 6.0;
      }

      // 5. Pair compatibility check
      bool hasCompatiblePair = false;
      for (int i = 0; i < combination.length; i++) {
        for (int j = i + 1; j < combination.length; j++) {
          final pKey = '${combination[i]}-${combination[j]}';
          if (topPairKeys.contains(pKey)) {
            totalScore += 12.0;
            hasCompatiblePair = true;
            explanations.add('Includes historical co-occurring pair: ${combination[i].toString().padLeft(2, '0')} - ${combination[j].toString().padLeft(2, '0')}.');
            break;
          }
        }
        if (hasCompatiblePair) break;
      }

      // Check for hot & overdue highlights
      final hotInComb = combination.where((n) => analytics.hotNumbers.any((h) => h.number == n)).toList();
      if (hotInComb.isNotEmpty) {
        explanations.add('Incorporates frequent number(s): ${hotInComb.map((e) => e.toString().padLeft(2, '0')).join(', ')} with high 1-year drawing frequency.');
      }

      candidates.add(_CandidateCombination(
        numbers: combination,
        score: (totalScore * 10).round() / 10.0, // round to 1 decimal place
        explanations: explanations,
      ));
    }

    // Sort descending by score and remove duplicate combinations
    candidates.sort((a, b) => b.score.compareTo(a.score));

    final distinctSuggestions = <StatisticalSuggestion>[];
    final seen = <String>{};

    for (final c in candidates) {
      final key = c.numbers.join('-');
      if (!seen.contains(key)) {
        seen.add(key);
        distinctSuggestions.add(StatisticalSuggestion(
          rank: distinctSuggestions.length + 1,
          numbers: c.numbers,
          statisticalScore: c.score,
          explanationPoints: c.explanations,
        ));
      }
      if (distinctSuggestions.length >= count) break;
    }

    return distinctSuggestions;
  }

  List<StatisticalSuggestion> _generateDefaultSuggestions(LottoType lottoType, int count) {
    final list = <StatisticalSuggestion>[];
    for (int i = 1; i <= count; i++) {
      final step = (lottoType.maxNumber / 6).floor();
      final nums = [
        1 + (i % 3),
        step + i,
        (step * 2) + i,
        (step * 3) + i,
        (step * 4) + i,
        min(lottoType.maxNumber, (step * 5) + i),
      ]..sort();

      list.add(StatisticalSuggestion(
        rank: i,
        numbers: nums,
        statisticalScore: 70.0 - (i * 2.0),
        explanationPoints: [
          'Uniform mathematical spread across the 1–${lottoType.maxNumber} number range.',
          'Maintains balanced odd/even ratio.',
        ],
      ));
    }
    return list;
  }
}

class _CandidateCombination {
  final List<int> numbers;
  final double score;
  final List<String> explanations;

  _CandidateCombination({
    required this.numbers,
    required this.score,
    required this.explanations,
  });
}
