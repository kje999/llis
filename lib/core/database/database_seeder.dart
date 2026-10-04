import 'dart:math';
import 'package:intl/intl.dart';
import 'database_executor.dart';
import '../security/password_hasher.dart';

class DatabaseSeeder {
  static Future<void> seed(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();

    // 1. Seed the 5 FIXED lotto types
    final lottoTypes = [
      {
        'id': 1,
        'code': 'ULTRA_6_58',
        'name': 'Ultra Lotto 6/58',
        'min_number': 1,
        'max_number': 58,
        'number_count': 6,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 2,
        'code': 'GRAND_6_55',
        'name': 'Grand Lotto 6/55',
        'min_number': 1,
        'max_number': 55,
        'number_count': 6,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 3,
        'code': 'SUPER_6_49',
        'name': 'Super Lotto 6/49',
        'min_number': 1,
        'max_number': 49,
        'number_count': 6,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 4,
        'code': 'MEGA_6_45',
        'name': 'Mega Lotto 6/45',
        'min_number': 1,
        'max_number': 45,
        'number_count': 6,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 5,
        'code': 'LOTTO_6_42',
        'name': 'Lotto 6/42',
        'min_number': 1,
        'max_number': 42,
        'number_count': 6,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final type in lottoTypes) {
      await db.insert('lotto_types', type);
    }

    // 2. Seed Default Admin & Client accounts
    // ADMIN / ADMIN (password hashed with SHA-256)
    await db.insert('users', {
      'id': 1,
      'username': 'ADMIN',
      'password_hash': PasswordHasher.hash('ADMIN'),
      'role': 'ADMIN',
      'full_name': 'Administrator',
      'email': 'admin@pcso-llis.gov.ph',
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
    });

    // Client user
    await db.insert('users', {
      'id': 2,
      'username': 'kenth',
      'password_hash': PasswordHasher.hash('password123'),
      'role': 'CLIENT',
      'full_name': 'Kenth Joshua Espina',
      'email': 'kenth@example.com',
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
    });

    // 3. Seed Default App Settings
    final defaultSettings = [
      {'setting_key': 'automatic_sync_enabled', 'setting_value': 'true', 'updated_at': now},
      {'setting_key': 'sync_interval', 'setting_value': 'Every 1 hour', 'updated_at': now},
      {'setting_key': 'tts_enabled', 'setting_value': 'true', 'updated_at': now},
      {'setting_key': 'default_lotto_type', 'setting_value': 'ULTRA_6_58', 'updated_at': now},
      {'setting_key': 'analysis_period', 'setting_value': 'Last 1 Year', 'updated_at': now},
      {'setting_key': 'last_sync', 'setting_value': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()), 'updated_at': now},
    ];

    for (final s in defaultSettings) {
      await db.insert('app_settings', s);
    }

    // 4. Seed realistic 1-year historical lotto results for all 5 games (draws 2-3x a week)
    final random = Random(42); // deterministic seed for reproducibility
    final baseDate = DateTime.now();

    // Game configurations: [typeId, maxNum, baseJackpot]
    final gamesConfig = [
      [1, 58, 49500000.0],
      [2, 55, 29800000.0],
      [3, 49, 15800000.0],
      [4, 45, 8900000.0],
      [5, 42, 5900000.0],
    ];

    int resultId = 1;
    // Generate ~52 weeks of draws (approx 104 draws per game over the past year)
    for (int dayOffset = 365; dayOffset >= 0; dayOffset -= 3) {
      final drawDate = baseDate.subtract(Duration(days: dayOffset));
      final dateStr = DateFormat('yyyy-MM-dd').format(drawDate);

      for (final cfg in gamesConfig) {
        final typeId = cfg[0] as int;
        final maxNum = cfg[1] as int;
        final baseJackpot = cfg[2] as double;

        // Pick 6 unique random numbers in range 1..maxNum
        final numbers = <int>{};
        while (numbers.length < 6) {
          numbers.add(random.nextInt(maxNum) + 1);
        }
        final sortedList = numbers.toList()..sort();

        await db.insert('lotto_results', {
          'id': resultId++,
          'lotto_type_id': typeId,
          'draw_date': dateStr,
          'number_1': sortedList[0],
          'number_2': sortedList[1],
          'number_3': sortedList[2],
          'number_4': sortedList[3],
          'number_5': sortedList[4],
          'number_6': sortedList[5],
          'jackpot_prize': baseJackpot + (random.nextInt(50) * 1000000),
          'source': 'PCSO',
          'source_url': 'https://www.pcso.gov.ph/searchlottoresult.aspx',
          'scraped_at': now,
          'created_at': now,
          'updated_at': now,
        });
      }
    }

    // 5. Seed some sample saved picks for client user (id: 2)
    final samplePickNumbers = [
      [4, 12, 19, 27, 34, 58],
      [5, 12, 19, 27, 38, 44],
      [3, 11, 17, 26, 38, 45],
      [4, 9, 16, 27, 34, 42],
      [2, 8, 15, 23, 31, 40],
    ];

    for (int i = 0; i < 5; i++) {
      final pickDate = DateFormat('yyyy-MM-dd').format(baseDate.subtract(Duration(days: i * 3)));
      final nums = samplePickNumbers[i];
      await db.insert('lucky_picks', {
        'id': i + 1,
        'user_id': 2,
        'lotto_type_id': i + 1,
        'draw_date': pickDate,
        'number_1': nums[0],
        'number_2': nums[1],
        'number_3': nums[2],
        'number_4': nums[3],
        'number_5': nums[4],
        'number_6': nums[5],
        'generated_at': now,
        'is_checked': 1,
        'match_count': 2 + (i % 3),
        'status': (2 + (i % 3)) >= 3 ? 'PARTIAL_MATCH' : 'NOT_WINNING',
      });
    }

    // 6. Seed initial audit log
    await db.insert('audit_logs', {
      'user_id': 1,
      'action': 'SYSTEM_INIT',
      'entity_type': 'SYSTEM',
      'entity_id': null,
      'description': 'Database initialized with fixed PCSO lotto configuration and 1-year history.',
      'created_at': now,
    });
  }
}
