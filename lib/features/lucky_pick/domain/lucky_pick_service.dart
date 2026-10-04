import 'dart:math';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';

class LuckyPickService {
  final Random _random = Random.secure();

  /// Generates exactly 6 unique numbers within the game's valid range [minNumber..maxNumber],
  /// sorted ascending.
  List<int> generateNumbers(LottoType lottoType) {
    validateLottoType(lottoType);

    final selected = <int>{};
    final range = lottoType.maxNumber - lottoType.minNumber + 1;

    while (selected.length < 6) {
      final num = lottoType.minNumber + _random.nextInt(range);
      selected.add(num);
    }

    final sorted = selected.toList()..sort();
    return sorted;
  }

  /// Validates a list of 6 numbers against the specific lotto game rules
  bool validateCombination(LottoType lottoType, List<int> numbers) {
    if (numbers.length != 6) return false;

    // Check uniqueness
    final set = numbers.toSet();
    if (set.length != 6) return false;

    // Check bounds
    for (final n in numbers) {
      if (n < lottoType.minNumber || n > lottoType.maxNumber) {
        return false;
      }
    }
    return true;
  }

  void validateLottoType(LottoType lottoType) {
    if (lottoType.maxNumber < 42 || lottoType.maxNumber > 58) {
      throw ArgumentError('Invalid PCSO 6-number lotto type: ${lottoType.name}');
    }
  }

  /// Evaluates user's saved pick against official draw numbers
  /// Returns count of matching numbers [0..6]
  int countMatches(List<int> pickNumbers, List<int> officialNumbers) {
    final pickSet = pickNumbers.toSet();
    final officialSet = officialNumbers.toSet();
    return pickSet.intersection(officialSet).length;
  }

  /// Calculates status string: PENDING, NOT_WINNING, PARTIAL_MATCH, WINNER
  String determineStatus(int matchCount) {
    if (matchCount == 6) {
      return 'WINNER';
    } else if (matchCount >= 3) {
      return 'PARTIAL_MATCH';
    } else {
      return 'NOT_WINNING';
    }
  }
}
