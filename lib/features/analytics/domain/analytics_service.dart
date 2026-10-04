import 'dart:math';
import '../../shared/models/lotto_result.dart';
import '../../shared/models/lotto_type.dart';

class NumberFrequency {
  final int number;
  final int count;
  final double percentage;
  final int drawsSince;
  final String? lastDrawnDate;

  NumberFrequency({
    required this.number,
    required this.count,
    required this.percentage,
    required this.drawsSince,
    this.lastDrawnDate,
  });
}

class NumberPairStat {
  final int number1;
  final int number2;
  final int count;

  NumberPairStat({required this.number1, required this.number2, required this.count});

  String get label => '${number1.toString().padLeft(2, '0')} - ${number2.toString().padLeft(2, '0')}';
}

class OddEvenStat {
  final int oddCount;
  final int evenCount;
  final int occurrences;
  final double percentage;

  OddEvenStat({required this.oddCount, required this.evenCount, required this.occurrences, required this.percentage});

  String get pattern => '$oddCount Odd / $evenCount Even';
}

class LowHighStat {
  final int lowCount;
  final int highCount;
  final int occurrences;
  final double percentage;

  LowHighStat({required this.lowCount, required this.highCount, required this.occurrences, required this.percentage});

  String get pattern => '$lowCount Low / $highCount High';
}

class SumStatistics {
  final int minSum;
  final int maxSum;
  final double avgSum;
  final double medianSum;
  final double standardDeviation;
  final String commonRange;

  SumStatistics({
    required this.minSum,
    required this.maxSum,
    required this.avgSum,
    required this.medianSum,
    required this.standardDeviation,
    required this.commonRange,
  });
}

class RepeatedNumberStat {
  final int repeatCount;
  final int occurrences;
  final double percentage;

  RepeatedNumberStat({required this.repeatCount, required this.occurrences, required this.percentage});
}

class AnalyticsResult {
  final LottoType lottoType;
  final int totalDrawsAnalyzed;
  final List<NumberFrequency> allFrequencies;
  final List<NumberFrequency> hotNumbers;
  final List<NumberFrequency> coldNumbers;
  final List<NumberFrequency> overdueNumbers;
  final List<NumberPairStat> topPairs;
  final List<OddEvenStat> oddEvenDistribution;
  final List<LowHighStat> lowHighDistribution;
  final SumStatistics sumStatistics;
  final List<RepeatedNumberStat> repeatedStats;

  AnalyticsResult({
    required this.lottoType,
    required this.totalDrawsAnalyzed,
    required this.allFrequencies,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.overdueNumbers,
    required this.topPairs,
    required this.oddEvenDistribution,
    required this.lowHighDistribution,
    required this.sumStatistics,
    required this.repeatedStats,
  });
}

class AnalyticsService {
  /// Analyzes historical draws strictly for the specified lotto game.
  AnalyticsResult analyze({
    required LottoType lottoType,
    required List<LottoResult> draws,
  }) {
    if (draws.isEmpty) {
      return _emptyResult(lottoType);
    }

    // Sort draws ascending by date for chronological analytics
    final sortedDraws = List<LottoResult>.from(draws)
      ..sort((a, b) => a.drawDate.compareTo(b.drawDate));

    final totalDraws = sortedDraws.length;
    final totalNumbersDrawn = totalDraws * 6;

    // 1. Calculate Frequency & Overdue (Draws Since)
    final freqMap = <int, int>{};
    final lastDrawnDrawIndex = <int, int>{};
    final lastDrawnDateMap = <int, String>{};

    for (int i = 1; i <= lottoType.maxNumber; i++) {
      freqMap[i] = 0;
      lastDrawnDrawIndex[i] = -1;
    }

    for (int idx = 0; idx < sortedDraws.length; idx++) {
      final draw = sortedDraws[idx];
      for (final n in draw.numbers) {
        freqMap[n] = (freqMap[n] ?? 0) + 1;
        lastDrawnDrawIndex[n] = idx;
        lastDrawnDateMap[n] = draw.drawDate;
      }
    }

    final allFreqs = <NumberFrequency>[];
    for (int i = 1; i <= lottoType.maxNumber; i++) {
      final count = freqMap[i] ?? 0;
      final pct = totalNumbersDrawn > 0 ? (count / totalDraws) * 100 : 0.0;
      final lastIdx = lastDrawnDrawIndex[i] ?? -1;
      final drawsSince = lastIdx == -1 ? totalDraws : (totalDraws - 1 - lastIdx);
      allFreqs.add(NumberFrequency(
        number: i,
        count: count,
        percentage: pct,
        drawsSince: drawsSince,
        lastDrawnDate: lastDrawnDateMap[i],
      ));
    }

    // Hot numbers (Highest frequencies)
    final hotNumbers = List<NumberFrequency>.from(allFreqs)
      ..sort((a, b) => b.count.compareTo(a.count));
    final topHot = hotNumbers.take(6).toList();

    // Cold numbers (Lowest frequencies)
    final coldNumbers = List<NumberFrequency>.from(allFreqs)
      ..sort((a, b) => a.count.compareTo(b.count));
    final topCold = coldNumbers.take(6).toList();

    // Overdue numbers (Highest drawsSince)
    final overdueNumbers = List<NumberFrequency>.from(allFreqs)
      ..sort((a, b) => b.drawsSince.compareTo(a.drawsSince));
    final topOverdue = overdueNumbers.take(6).toList();

    // 2. Number Pairs Analysis
    final pairMap = <String, int>{};
    for (final draw in sortedDraws) {
      final nums = draw.numbers;
      for (int i = 0; i < nums.length; i++) {
        for (int j = i + 1; j < nums.length; j++) {
          final n1 = min(nums[i], nums[j]);
          final n2 = max(nums[i], nums[j]);
          final key = '$n1-$n2';
          pairMap[key] = (pairMap[key] ?? 0) + 1;
        }
      }
    }

    final pairList = <NumberPairStat>[];
    pairMap.forEach((key, count) {
      final parts = key.split('-').map(int.parse).toList();
      pairList.add(NumberPairStat(number1: parts[0], number2: parts[1], count: count));
    });
    pairList.sort((a, b) => b.count.compareTo(a.count));
    final topPairs = pairList.take(8).toList();

    // 3. Odd / Even Distribution
    final oddEvenMap = <String, int>{};
    for (final draw in sortedDraws) {
      int odd = 0;
      for (final n in draw.numbers) {
        if (n % 2 != 0) odd++;
      }
      final key = '$odd-${6 - odd}';
      oddEvenMap[key] = (oddEvenMap[key] ?? 0) + 1;
    }

    final oddEvenList = <OddEvenStat>[];
    oddEvenMap.forEach((key, count) {
      final parts = key.split('-').map(int.parse).toList();
      oddEvenList.add(OddEvenStat(
        oddCount: parts[0],
        evenCount: parts[1],
        occurrences: count,
        percentage: (count / totalDraws) * 100,
      ));
    });
    oddEvenList.sort((a, b) => b.occurrences.compareTo(a.occurrences));

    // 4. Low / High Distribution (dynamically split based on maxNumber)
    final midPoint = lottoType.maxNumber ~/ 2;
    final lowHighMap = <String, int>{};
    for (final draw in sortedDraws) {
      int low = 0;
      for (final n in draw.numbers) {
        if (n <= midPoint) low++;
      }
      final key = '$low-${6 - low}';
      lowHighMap[key] = (lowHighMap[key] ?? 0) + 1;
    }

    final lowHighList = <LowHighStat>[];
    lowHighMap.forEach((key, count) {
      final parts = key.split('-').map(int.parse).toList();
      lowHighList.add(LowHighStat(
        lowCount: parts[0],
        highCount: parts[1],
        occurrences: count,
        percentage: (count / totalDraws) * 100,
      ));
    });
    lowHighList.sort((a, b) => b.occurrences.compareTo(a.occurrences));

    // 5. Sum Analysis
    final sums = <int>[];
    for (final draw in sortedDraws) {
      final sum = draw.numbers.reduce((a, b) => a + b);
      sums.add(sum);
    }
    sums.sort();

    final minSum = sums.first;
    final maxSum = sums.last;
    final avgSum = sums.reduce((a, b) => a + b) / sums.length;
    final medianSum = sums[sums.length ~/ 2].toDouble();

    // Standard deviation
    double varianceSum = 0;
    for (final s in sums) {
      varianceSum += pow(s - avgSum, 2);
    }
    final stdDev = sqrt(varianceSum / sums.length);
    final commonRange = '${(avgSum - stdDev).round()}–${(avgSum + stdDev).round()}';

    final sumStats = SumStatistics(
      minSum: minSum,
      maxSum: maxSum,
      avgSum: avgSum,
      medianSum: medianSum,
      standardDeviation: stdDev,
      commonRange: commonRange,
    );

    // 6. Repeated numbers between consecutive draws
    final repeatMap = <int, int>{};
    for (int i = 0; i <= 6; i++) {
      repeatMap[i] = 0;
    }

    for (int i = 1; i < sortedDraws.length; i++) {
      final prev = sortedDraws[i - 1].numbers.toSet();
      final curr = sortedDraws[i].numbers.toSet();
      final common = prev.intersection(curr).length;
      repeatMap[common] = (repeatMap[common] ?? 0) + 1;
    }

    final consecutiveComparisons = totalDraws > 1 ? totalDraws - 1 : 1;
    final repeatStats = <RepeatedNumberStat>[];
    for (int i = 0; i <= 4; i++) {
      final count = repeatMap[i] ?? 0;
      repeatStats.add(RepeatedNumberStat(
        repeatCount: i,
        occurrences: count,
        percentage: (count / consecutiveComparisons) * 100,
      ));
    }

    return AnalyticsResult(
      lottoType: lottoType,
      totalDrawsAnalyzed: totalDraws,
      allFrequencies: allFreqs,
      hotNumbers: topHot,
      coldNumbers: topCold,
      overdueNumbers: topOverdue,
      topPairs: topPairs,
      oddEvenDistribution: oddEvenList,
      lowHighDistribution: lowHighList,
      sumStatistics: sumStats,
      repeatedStats: repeatStats,
    );
  }

  AnalyticsResult _emptyResult(LottoType lottoType) {
    return AnalyticsResult(
      lottoType: lottoType,
      totalDrawsAnalyzed: 0,
      allFrequencies: [],
      hotNumbers: [],
      coldNumbers: [],
      overdueNumbers: [],
      topPairs: [],
      oddEvenDistribution: [],
      lowHighDistribution: [],
      sumStatistics: SumStatistics(
        minSum: 0,
        maxSum: 0,
        avgSum: 0,
        medianSum: 0,
        standardDeviation: 0,
        commonRange: 'N/A',
      ),
      repeatedStats: [],
    );
  }
}
