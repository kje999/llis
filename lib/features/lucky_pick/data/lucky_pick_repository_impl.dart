import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_lucky_lotto_pred/core/constants/api_constants.dart';
import 'package:my_lucky_lotto_pred/core/database/database_executor.dart';
import 'package:my_lucky_lotto_pred/shared/models/lucky_pick.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';

class LuckyPickRepositoryImpl implements LuckyPickRepository {
  final DatabaseExecutor _db;

  LuckyPickRepositoryImpl(this._db);

  @override
  Future<List<LuckyPick>> getByUserId(int userId, {String? username}) async {
    await syncPicksFromBackend(userId: userId, username: username);
    const sql = '''
      SELECT p.*, t.name as lotto_type_name, t.code as lotto_type_code
      FROM lucky_picks p
      JOIN lotto_types t ON p.lotto_type_id = t.id
      WHERE p.user_id = ?
      ORDER BY p.generated_at DESC
    ''';
    final rows = await _db.query(sql, [userId]);
    return rows.map((r) => LuckyPick.fromMap(r)).toList();
  }

  @override
  Future<int> syncPicksFromBackend({int? userId, String? username}) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId.toString();
      if (username != null && username.isNotEmpty) queryParams['username'] = username;

      final uri = Uri.parse(ApiConstants.picksEndpoint).replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return 0;

      final dynamic decoded = jsonDecode(res.body);
      if (decoded is! List || decoded.isEmpty) return 0;

      int inserted = 0;
      final existingAll = await _db.query('SELECT * FROM lucky_picks');
      for (final item in decoded) {
        if (item is! Map) continue;
        final raw = Map<String, dynamic>.from(item);

        final pUserId = userId ?? (raw['user_id'] as num?)?.toInt() ?? 0;
        final lottoTypeId = (raw['lotto_type_id'] as num?)?.toInt() ?? 1;
        final drawDate = raw['draw_date']?.toString() ?? '';
        final n1 = (raw['number_1'] as num?)?.toInt() ?? 0;
        final n2 = (raw['number_2'] as num?)?.toInt() ?? 0;
        final n3 = (raw['number_3'] as num?)?.toInt() ?? 0;
        final n4 = (raw['number_4'] as num?)?.toInt() ?? 0;
        final n5 = (raw['number_5'] as num?)?.toInt() ?? 0;
        final n6 = (raw['number_6'] as num?)?.toInt() ?? 0;

        // In-memory robust deduplication check
        Map<String, dynamic>? match;
        for (final r in existingAll) {
          final rUid = (r['user_id'] as num?)?.toInt();
          final rLotto = (r['lotto_type_id'] as num?)?.toInt();
          final rDate = r['draw_date']?.toString();
          final rn1 = (r['number_1'] as num?)?.toInt();
          final rn2 = (r['number_2'] as num?)?.toInt();
          final rn3 = (r['number_3'] as num?)?.toInt();
          final rn4 = (r['number_4'] as num?)?.toInt();
          final rn5 = (r['number_5'] as num?)?.toInt();
          final rn6 = (r['number_6'] as num?)?.toInt();

          final isUserMatch = (rUid == pUserId) || (userId != null && rUid == (raw['user_id'] as num?)?.toInt());
          if (isUserMatch &&
              rLotto == lottoTypeId &&
              rDate == drawDate &&
              rn1 == n1 && rn2 == n2 && rn3 == n3 &&
              rn4 == n4 && rn5 == n5 && rn6 == n6) {
            match = r;
            break;
          }
        }

        final isChecked = (raw['is_checked'] == 1 || raw['is_checked'] == true);
        final matchCount = (raw['match_count'] as num?)?.toInt() ?? 0;
        final status = raw['status']?.toString() ?? 'PENDING';

        if (match == null) {
          await _db.insert('lucky_picks', {
            'user_id': pUserId,
            'lotto_type_id': lottoTypeId,
            'draw_date': drawDate,
            'number_1': n1,
            'number_2': n2,
            'number_3': n3,
            'number_4': n4,
            'number_5': n5,
            'number_6': n6,
            'generated_at': raw['generated_at']?.toString() ?? DateTime.now().toIso8601String(),
            'is_checked': isChecked ? 1 : 0,
            'match_count': matchCount,
            'status': status,
          });
          inserted++;
        } else {
          // If match found, ensure user_id and status are updated to current state
          await _db.update(
            'lucky_picks',
            {
              'user_id': pUserId,
              'is_checked': isChecked ? 1 : 0,
              'match_count': matchCount,
              'status': status,
            },
            where: 'id = ?',
            whereArgs: [match['id']],
          );
        }
      }
      return inserted;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<List<LuckyPick>> getUncheckedPicks(int lottoTypeId, String drawDate) async {
    const sql = '''
      SELECT p.*, t.name as lotto_type_name, t.code as lotto_type_code
      FROM lucky_picks p
      JOIN lotto_types t ON p.lotto_type_id = t.id
      WHERE p.lotto_type_id = ? AND p.draw_date = ? AND p.is_checked = 0
    ''';
    final rows = await _db.query(sql, [lottoTypeId, drawDate]);
    return rows.map((r) => LuckyPick.fromMap(r)).toList();
  }

  @override
  Future<int> insert(LuckyPick pick, {String? username}) async {
    final map = pick.toMap()..remove('id');
    final id = await _db.insert('lucky_picks', map);

    // Sync to backend central SQLite database
    try {
      await http.post(
        Uri.parse(ApiConstants.picksSyncEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': pick.userId,
          if (username != null) 'username': username,
          'lotto_type_id': pick.lottoTypeId,
          'draw_date': pick.drawDate,
          'numbers': pick.numbers,
          'is_checked': pick.isChecked,
          'match_count': pick.matchCount,
          'status': pick.status,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    return id;
  }

  @override
  Future<void> update(LuckyPick pick) async {
    await _db.update(
      'lucky_picks',
      pick.toMap(),
      where: 'id = ?',
      whereArgs: [pick.id],
    );

    // Sync update to backend central SQLite database
    try {
      await http.post(
        Uri.parse(ApiConstants.picksSyncEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': pick.userId,
          'lotto_type_id': pick.lottoTypeId,
          'draw_date': pick.drawDate,
          'numbers': pick.numbers,
          'is_checked': pick.isChecked,
          'match_count': pick.matchCount,
          'status': pick.status,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('lucky_picks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> getTotalCount() async {
    final rows = await _db.query('SELECT COUNT(*) as count FROM lucky_picks');
    if (rows.isEmpty) return 0;
    return rows.first['count'] as int? ?? 0;
  }
}
