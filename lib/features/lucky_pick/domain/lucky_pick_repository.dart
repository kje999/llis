import 'package:my_lucky_lotto_pred/shared/models/lucky_pick.dart';

abstract class LuckyPickRepository {
  Future<List<LuckyPick>> getByUserId(int userId);
  Future<List<LuckyPick>> getUncheckedPicks(int lottoTypeId, String drawDate);
  Future<int> insert(LuckyPick pick);
  Future<void> update(LuckyPick pick);
  Future<void> delete(int id);
  Future<int> getTotalCount();
}
