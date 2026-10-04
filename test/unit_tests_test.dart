import 'package:flutter_test/flutter_test.dart';
import 'package:my_lucky_lotto_pred/core/security/password_hasher.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_service.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/pcso_parser.dart';
import 'package:my_lucky_lotto_pred/features/analytics/domain/analytics_service.dart';
import 'package:my_lucky_lotto_pred/features/predictions/domain/prediction_engine.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';

void main() {
  group('LuckyPickService Tests', () {
    final pickService = LuckyPickService();
    final ultra58 = LottoType(
      id: 1,
      code: 'ULTRA_6_58',
      name: 'Ultra Lotto 6/58',
      minNumber: 1,
      maxNumber: 58,
      numberCount: 6,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('generates exactly 6 unique numbers within valid range and sorted', () {
      final numbers = pickService.generateNumbers(ultra58);
      expect(numbers.length, equals(6));
      expect(numbers.toSet().length, equals(6));

      for (final n in numbers) {
        expect(n >= 1 && n <= 58, isTrue);
      }

      for (int i = 0; i < numbers.length - 1; i++) {
        expect(numbers[i] < numbers[i + 1], isTrue);
      }
    });

    test('validates combination bounds strictly rejecting numbers > 58', () {
      expect(pickService.validateCombination(ultra58, [4, 12, 19, 27, 34, 58]), isTrue);
      expect(pickService.validateCombination(ultra58, [4, 12, 19, 27, 34, 59]), isFalse);
      expect(pickService.validateCombination(ultra58, [0, 12, 19, 27, 34, 58]), isFalse);
      expect(pickService.validateCombination(ultra58, [4, 4, 19, 27, 34, 58]), isFalse); // duplicate
    });

    test('counts matches correctly', () {
      final userPick = [4, 12, 19, 27, 34, 58];
      final draw1 = [4, 12, 19, 30, 40, 50];
      final draw2 = [1, 2, 3, 5, 6, 7];

      expect(pickService.countMatches(userPick, draw1), equals(3));
      expect(pickService.determineStatus(3), equals('PARTIAL_MATCH'));

      expect(pickService.countMatches(userPick, draw2), equals(0));
      expect(pickService.determineStatus(0), equals('NOT_WINNING'));

      expect(pickService.determineStatus(6), equals('WINNER'));
    });
  });

  group('PcsoParser Tests', () {
    test('normalizes supported 5 lotto games and rejects non-supported', () {
      expect(PcsoParser.normalizeGameCode('Ultra Lotto 6/58'), equals('ULTRA_6_58'));
      expect(PcsoParser.normalizeGameCode('Grand Lotto 6/55'), equals('GRAND_6_55'));
      expect(PcsoParser.normalizeGameCode('Super Lotto 6/49'), equals('SUPER_6_49'));
      expect(PcsoParser.normalizeGameCode('Mega Lotto 6/45'), equals('MEGA_6_45'));
      expect(PcsoParser.normalizeGameCode('Lotto 6/42'), equals('LOTTO_6_42'));

      // Reject other PCSO games
      expect(PcsoParser.normalizeGameCode('6D Lotto'), isNull);
      expect(PcsoParser.normalizeGameCode('Swertres 3D'), isNull);
      expect(PcsoParser.normalizeGameCode('EZ2 2D Lotto'), isNull);
    });

    test('parses numbers string safely', () {
      final nums = PcsoParser.parseNumbers('04-12-19-27-34-58');
      expect(nums, equals([4, 12, 19, 27, 34, 58]));

      final commaNums = PcsoParser.parseNumbers('04, 12, 19, 27, 34, 58');
      expect(commaNums, equals([4, 12, 19, 27, 34, 58]));

      // Reject non-6 or duplicate
      expect(PcsoParser.parseNumbers('04-12-19-27-34'), isNull);
      expect(PcsoParser.parseNumbers('04-04-19-27-34-58'), isNull);
    });
  });

  group('PasswordHasher Tests', () {
    test('hashes password consistently and verifies correctly', () {
      final hash = PasswordHasher.hash('ADMIN');
      expect(hash.isNotEmpty, isTrue);
      expect(PasswordHasher.verify('ADMIN', hash), isTrue);
      expect(PasswordHasher.verify('wrong_pass', hash), isFalse);
    });
  });

  group('Analytics and Prediction Engine Tests', () {
    final analyticsService = AnalyticsService();
    final predictionEngine = PredictionEngine();

    final lotto642 = LottoType(
      id: 5,
      code: 'LOTTO_6_42',
      name: 'Lotto 6/42',
      minNumber: 1,
      maxNumber: 42,
      numberCount: 6,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockDraws = [
      LottoResult(
        id: 1,
        lottoTypeId: 5,
        drawDate: '2026-09-01',
        number1: 2,
        number2: 8,
        number3: 15,
        number4: 23,
        number5: 31,
        number6: 40,
        jackpotPrize: 6000000,
        scrapedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      LottoResult(
        id: 2,
        lottoTypeId: 5,
        drawDate: '2026-09-04',
        number1: 8,
        number2: 15,
        number3: 20,
        number4: 25,
        number5: 35,
        number6: 42,
        jackpotPrize: 6500000,
        scrapedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('analyzes frequencies separately per lotto type', () {
      final result = analyticsService.analyze(lottoType: lotto642, draws: mockDraws);
      expect(result.totalDrawsAnalyzed, equals(2));
      expect(result.allFrequencies.length, equals(42));

      // 8 and 15 appeared in both draws
      final num8 = result.allFrequencies.firstWhere((f) => f.number == 8);
      expect(num8.count, equals(2));
    });

    test('generates ranked explainable statistical suggestions', () {
      final suggestions = predictionEngine.generateSuggestions(
        lottoType: lotto642,
        historicalDraws: mockDraws,
        count: 5,
      );

      expect(suggestions.length, equals(5));
      for (final s in suggestions) {
        expect(s.numbers.length, equals(6));
        expect(s.numbers.toSet().length, equals(6));
        for (final n in s.numbers) {
          expect(n >= 1 && n <= 42, isTrue);
        }
        expect(s.explanationPoints.isNotEmpty, isTrue);
      }
    });
  });
}
