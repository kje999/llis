import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';

class RawPcsoDraw {
  final String gameName;
  final String drawDate; // e.g. "10/4/2026" or "2026-10-04"
  final List<int> numbers;
  final double jackpot;
  final int winners;

  RawPcsoDraw({
    required this.gameName,
    required this.drawDate,
    required this.numbers,
    required this.jackpot,
    this.winners = 0,
  });
}

class PcsoParser {
  /// Standardizes game names from PCSO search results to LLIS supported game codes
  static String? normalizeGameCode(String rawName) {
    final clean = rawName.toUpperCase();
    if (clean.contains('ULTRA') || clean.contains('6/58')) {
      return 'ULTRA_6_58';
    } else if (clean.contains('GRAND') || clean.contains('6/55')) {
      return 'GRAND_6_55';
    } else if (clean.contains('SUPER') || clean.contains('6/49')) {
      return 'SUPER_6_49';
    } else if (clean.contains('MEGA') || clean.contains('6/45')) {
      return 'MEGA_6_45';
    } else if (clean.contains('LOTTO 6/42') || clean.contains('6/42')) {
      return 'LOTTO_6_42';
    }
    // Reject 6D, 4D, Swertres, EZ2, etc.
    return null;
  }

  /// Parses draw numbers string like "04-12-19-27-34-58" or "04, 12, 19, 27, 34, 58"
  static List<int>? parseNumbers(String rawNumbers) {
    final clean = rawNumbers.replaceAll(',', '-').replaceAll(' ', '');
    final parts = clean.split('-');
    if (parts.length != 6) return null;

    final numbers = <int>[];
    for (final p in parts) {
      final parsed = int.tryParse(p);
      if (parsed == null) return null;
      numbers.add(parsed);
    }

    // Verify exactly 6 unique numbers
    if (numbers.toSet().length != 6) return null;

    return numbers..sort();
  }

  /// Parses jackpot prize string like "49,500,000.00" or "₱49,500,000"
  static double parseJackpot(String rawPrize) {
    final clean = rawPrize.replaceAll('₱', '').replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  /// Parses number of winners like "0", "1", "179"
  static int parseWinners(String rawWinners) {
    final clean = rawWinners.replaceAll(',', '').replaceAll(' ', '').trim();
    return int.tryParse(clean) ?? 0;
  }

  /// Normalizes PCSO date format "10/4/2026" or "10/04/2026" into ISO "2026-10-04"
  static String parseDrawDate(String rawDate) {
    final clean = rawDate.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(clean)) {
      return clean;
    }
    final mdyMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(clean);
    if (mdyMatch != null) {
      final month = mdyMatch.group(1)!.padLeft(2, '0');
      final day = mdyMatch.group(2)!.padLeft(2, '0');
      final year = mdyMatch.group(3)!;
      return '$year-$month-$day';
    }
    return clean;
  }

  /// Validates numbers against game range
  static bool validateAgainstType(LottoType lottoType, List<int> numbers) {
    if (numbers.length != 6) return false;
    for (final n in numbers) {
      if (n < lottoType.minNumber || n > lottoType.maxNumber) {
        return false;
      }
    }
    return true;
  }
}
