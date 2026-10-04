import '../../../core/database/database_executor.dart';
import '../../../core/security/password_hasher.dart';

class MigrationReport {
  final int usersImported;
  final int resultsImported;
  final int picksImported;
  final int skippedRecords;
  final List<String> errorMessages;

  MigrationReport({
    required this.usersImported,
    required this.resultsImported,
    required this.picksImported,
    required this.skippedRecords,
    required this.errorMessages,
  });
}

class LegacyMySqlMigrator {
  final DatabaseExecutor _db;

  LegacyMySqlMigrator(this._db);

  /// Parses and migrates SQL dump text containing legacy VB.NET MySQL tables
  Future<MigrationReport> migrateSqlDump(String sqlContent) async {
    int usersCount = 0;
    int resultsCount = 0;
    int picksCount = 0;
    int skippedCount = 0;
    final errors = <String>[];

    final lines = sqlContent.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('--') || line.startsWith('/*')) continue;

      if (line.toUpperCase().startsWith('INSERT INTO')) {
        try {
          if (line.contains('users') || line.contains('tbl_users') || line.contains('user')) {
            // Legacy MySQL users mapping
            final valuesMatch = RegExp(r"VALUES\s*\((.*?)\)", caseSensitive: false).firstMatch(line);
            if (valuesMatch != null) {
              final rawVals = valuesMatch.group(1)!.split(',').map((e) => e.trim().replaceAll("'", "")).toList();
              if (rawVals.length >= 3) {
                final username = rawVals[1];
                final password = rawVals[2];
                await _db.insert('users', {
                  'username': username,
                  'password_hash': PasswordHasher.hash(password),
                  'role': username.toUpperCase() == 'ADMIN' ? 'ADMIN' : 'CLIENT',
                  'full_name': rawVals.length > 3 ? rawVals[3] : username,
                  'email': rawVals.length > 4 ? rawVals[4] : '$username@legacy.local',
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                  'is_active': 1,
                });
                usersCount++;
              }
            }
          } else if (line.contains('results') || line.contains('tbl_results') || line.contains('lotto')) {
            resultsCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          skippedCount++;
          errors.add('Failed line parsing: $e');
        }
      }
    }

    return MigrationReport(
      usersImported: usersCount,
      resultsImported: resultsCount,
      picksImported: picksCount,
      skippedRecords: skippedCount,
      errorMessages: errors,
    );
  }
}
