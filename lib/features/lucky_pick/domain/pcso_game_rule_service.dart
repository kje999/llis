import 'package:intl/intl.dart';

class PcsoGameSchedule {
  final String code;
  final String name;
  final List<int> drawDaysOfWeek; // DateTime.monday = 1, sunday = 7
  final String drawDaysText;
  final String drawTimeText;

  const PcsoGameSchedule({
    required this.code,
    required this.name,
    required this.drawDaysOfWeek,
    required this.drawDaysText,
    this.drawTimeText = '9:00 PM PHT',
  });

  /// Check if the specified date is a valid draw day for this game
  bool isDrawDay(DateTime date) {
    return drawDaysOfWeek.contains(date.weekday);
  }

  /// Calculates the next upcoming draw date starting from a given date
  DateTime getNextDrawDate([DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, now.day);

    // If today is a draw day and it's already after 9:00 PM, move to tomorrow
    if (isDrawDay(candidate) &&
        (now.hour > 21 || (now.hour == 21 && now.minute > 0))) {
      candidate = candidate.add(const Duration(days: 1));
    }

    while (!isDrawDay(candidate)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// Returns friendly reminder string
  String getScheduleReminder() {
    return '$name draws every $drawDaysText at $drawTimeText.';
  }
}

class PcsoPrizeTier {
  final int matchCount;
  final String tierName;
  final String prizeDescription;
  final double? estimatedAmount;
  final bool isJackpot;
  final bool isFixed;

  const PcsoPrizeTier({
    required this.matchCount,
    required this.tierName,
    required this.prizeDescription,
    this.estimatedAmount,
    this.isJackpot = false,
    this.isFixed = false,
  });
}

class PcsoPrizeResult {
  final int matchCount;
  final String tierName;
  final String prizeDescription;
  final double estimatedOrJackpotAmount;
  final bool isWinning;
  final String statusBadge;
  final List<int> matchedNumbers;

  const PcsoPrizeResult({
    required this.matchCount,
    required this.tierName,
    required this.prizeDescription,
    required this.estimatedOrJackpotAmount,
    required this.isWinning,
    required this.statusBadge,
    required this.matchedNumbers,
  });
}

class PcsoGameRuleService {
  static const Map<String, PcsoGameSchedule> schedules = {
    'ULTRA_6_58': PcsoGameSchedule(
      code: 'ULTRA_6_58',
      name: 'Ultra Lotto 6/58',
      drawDaysOfWeek: [DateTime.tuesday, DateTime.friday, DateTime.sunday],
      drawDaysText: 'Tuesday, Friday, Sunday',
    ),
    'GRAND_6_55': PcsoGameSchedule(
      code: 'GRAND_6_55',
      name: 'Grand Lotto 6/55',
      drawDaysOfWeek: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
      drawDaysText: 'Monday, Wednesday, Saturday',
    ),
    'SUPER_6_49': PcsoGameSchedule(
      code: 'SUPER_6_49',
      name: 'Super Lotto 6/49',
      drawDaysOfWeek: [DateTime.tuesday, DateTime.thursday, DateTime.sunday],
      drawDaysText: 'Tuesday, Thursday, Sunday',
    ),
    'MEGA_6_45': PcsoGameSchedule(
      code: 'MEGA_6_45',
      name: 'Mega Lotto 6/45',
      drawDaysOfWeek: [DateTime.monday, DateTime.wednesday, DateTime.friday],
      drawDaysText: 'Monday, Wednesday, Friday',
    ),
    'LOTTO_6_42': PcsoGameSchedule(
      code: 'LOTTO_6_42',
      name: 'Lotto 6/42',
      drawDaysOfWeek: [DateTime.tuesday, DateTime.thursday, DateTime.saturday],
      drawDaysText: 'Tuesday, Thursday, Saturday',
    ),
  };

  /// Prize rules per PCSO official regulations
  static const Map<String, List<PcsoPrizeTier>> prizeTiers = {
    'ULTRA_6_58': [
      PcsoPrizeTier(
        matchCount: 6,
        tierName: 'Jackpot (1st Prize)',
        prizeDescription: 'Jackpot Prize (Minimum ₱49.5M+)',
        isJackpot: true,
      ),
      PcsoPrizeTier(
        matchCount: 5,
        tierName: '2nd Prize',
        prizeDescription: 'Up to ₱120,000.00 (Pari-mutuel)',
        estimatedAmount: 120000.0,
      ),
      PcsoPrizeTier(
        matchCount: 4,
        tierName: '3rd Prize',
        prizeDescription: 'Up to ₱2,000.00 (Pari-mutuel)',
        estimatedAmount: 2000.0,
      ),
      PcsoPrizeTier(
        matchCount: 3,
        tierName: '4th Prize',
        prizeDescription: '₱100.00 (Fixed)',
        estimatedAmount: 100.0,
        isFixed: true,
      ),
    ],
    'GRAND_6_55': [
      PcsoPrizeTier(
        matchCount: 6,
        tierName: 'Jackpot (1st Prize)',
        prizeDescription: 'Jackpot Prize (Minimum ₱29.7M+)',
        isJackpot: true,
      ),
      PcsoPrizeTier(
        matchCount: 5,
        tierName: '2nd Prize',
        prizeDescription: 'Up to ₱100,000.00 (Pari-mutuel)',
        estimatedAmount: 100000.0,
      ),
      PcsoPrizeTier(
        matchCount: 4,
        tierName: '3rd Prize',
        prizeDescription: 'Up to ₱1,500.00 (Pari-mutuel)',
        estimatedAmount: 1500.0,
      ),
      PcsoPrizeTier(
        matchCount: 3,
        tierName: '4th Prize',
        prizeDescription: '₱60.00 (Fixed)',
        estimatedAmount: 60.0,
        isFixed: true,
      ),
    ],
    'SUPER_6_49': [
      PcsoPrizeTier(
        matchCount: 6,
        tierName: 'Jackpot (1st Prize)',
        prizeDescription: 'Jackpot Prize (Minimum ₱15.8M+)',
        isJackpot: true,
      ),
      PcsoPrizeTier(
        matchCount: 5,
        tierName: '2nd Prize',
        prizeDescription: 'Up to ₱50,000.00 (Pari-mutuel)',
        estimatedAmount: 50000.0,
      ),
      PcsoPrizeTier(
        matchCount: 4,
        tierName: '3rd Prize',
        prizeDescription: 'Up to ₱1,200.00 (Pari-mutuel)',
        estimatedAmount: 1200.0,
      ),
      PcsoPrizeTier(
        matchCount: 3,
        tierName: '4th Prize',
        prizeDescription: '₱50.00 (Fixed)',
        estimatedAmount: 50.0,
        isFixed: true,
      ),
    ],
    'MEGA_6_45': [
      PcsoPrizeTier(
        matchCount: 6,
        tierName: 'Jackpot (1st Prize)',
        prizeDescription: 'Jackpot Prize (Minimum ₱8.9M+)',
        isJackpot: true,
      ),
      PcsoPrizeTier(
        matchCount: 5,
        tierName: '2nd Prize',
        prizeDescription: 'Up to ₱32,000.00 (Pari-mutuel)',
        estimatedAmount: 32000.0,
      ),
      PcsoPrizeTier(
        matchCount: 4,
        tierName: '3rd Prize',
        prizeDescription: 'Up to ₱1,000.00 (Pari-mutuel)',
        estimatedAmount: 1000.0,
      ),
      PcsoPrizeTier(
        matchCount: 3,
        tierName: '4th Prize',
        prizeDescription: '₱30.00 (Fixed)',
        estimatedAmount: 30.0,
        isFixed: true,
      ),
    ],
    'LOTTO_6_42': [
      PcsoPrizeTier(
        matchCount: 6,
        tierName: 'Jackpot (1st Prize)',
        prizeDescription: 'Jackpot Prize (Minimum ₱5.9M+)',
        isJackpot: true,
      ),
      PcsoPrizeTier(
        matchCount: 5,
        tierName: '2nd Prize',
        prizeDescription: 'Up to ₱24,000.00 (Pari-mutuel)',
        estimatedAmount: 24000.0,
      ),
      PcsoPrizeTier(
        matchCount: 4,
        tierName: '3rd Prize',
        prizeDescription: 'Up to ₱800.00 (Pari-mutuel)',
        estimatedAmount: 800.0,
      ),
      PcsoPrizeTier(
        matchCount: 3,
        tierName: '4th Prize',
        prizeDescription: '₱20.00 (Fixed)',
        estimatedAmount: 20.0,
        isFixed: true,
      ),
    ],
  };

  static PcsoGameSchedule? getSchedule(String gameCode) {
    return schedules[gameCode];
  }

  /// Returns prize rules per PCSO regulations, dynamically formatting the Jackpot
  /// based on the recent draw result jackpot if available.
  static List<PcsoPrizeTier> getPrizeTiersForGame(
    String gameCode, {
    double? dynamicJackpot,
    String? drawDate,
  }) {
    final baseTiers = prizeTiers[gameCode] ?? prizeTiers['LOTTO_6_42']!;
    if (dynamicJackpot == null || dynamicJackpot <= 0) {
      return baseTiers;
    }

    final currency = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );
    final formattedAmount = currency.format(dynamicJackpot);

    return baseTiers.map((tier) {
      if (tier.isJackpot) {
        return PcsoPrizeTier(
          matchCount: tier.matchCount,
          tierName: tier.tierName,
          prizeDescription: 'Jackpot Prize ($formattedAmount)',
          estimatedAmount: dynamicJackpot,
          isJackpot: true,
          isFixed: false,
        );
      }
      return tier;
    }).toList();
  }

  /// Calculates prize information for a given game and match count
  static PcsoPrizeResult calculatePrize({
    required String gameCode,
    required List<int> userNumbers,
    required List<int> officialNumbers,
    double jackpotPrize = 0.0,
  }) {
    final userSet = userNumbers.toSet();
    final officialSet = officialNumbers.toSet();
    final matched = userSet.intersection(officialSet).toList()..sort();
    final matchCount = matched.length;

    final tiers = prizeTiers[gameCode] ?? prizeTiers['LOTTO_6_42']!;
    final tier = tiers.firstWhere(
      (t) => t.matchCount == matchCount,
      orElse: () => PcsoPrizeTier(
        matchCount: matchCount,
        tierName: 'No Prize (Less than 3 matches)',
        prizeDescription:
            'Better luck next draw! No winning prize for $matchCount matching digits.',
        estimatedAmount: 0.0,
      ),
    );

    if (matchCount == 6) {
      final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
      final amount = jackpotPrize > 0
          ? jackpotPrize
          : (tier.estimatedAmount ?? 30000000.0);
      return PcsoPrizeResult(
        matchCount: 6,
        tierName: tier.tierName,
        prizeDescription:
            '🎉 CONGRATULATIONS! You matched all 6 numbers and won the Jackpot of ${currency.format(amount)}!',
        estimatedOrJackpotAmount: amount,
        isWinning: true,
        statusBadge: 'JACKPOT WINNER (6/6)',
        matchedNumbers: matched,
      );
    } else if (matchCount >= 3) {
      return PcsoPrizeResult(
        matchCount: matchCount,
        tierName: tier.tierName,
        prizeDescription:
            '🎯 You matched $matchCount numbers! Prize: ${tier.prizeDescription}',
        estimatedOrJackpotAmount: tier.estimatedAmount ?? 0.0,
        isWinning: true,
        statusBadge: '${tier.tierName} ($matchCount/6)',
        matchedNumbers: matched,
      );
    } else {
      return PcsoPrizeResult(
        matchCount: matchCount,
        tierName: 'No Prize',
        prizeDescription:
            'Matched $matchCount of 6 numbers. Official PCSO prize requires at least 3 matching numbers.',
        estimatedOrJackpotAmount: 0.0,
        isWinning: false,
        statusBadge: 'NO WIN ($matchCount/6)',
        matchedNumbers: matched,
      );
    }
  }
}
