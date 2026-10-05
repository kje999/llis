import 'package:intl/intl.dart';
import 'database_executor.dart';

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

    // 2. Default App Settings (User accounts are stored and loaded from the central SQLite database)
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

    // Only pre-seeded accounts and core system configuration are retained.
    // Lotto results and lucky picks start clean with 0 records.
  }
}
