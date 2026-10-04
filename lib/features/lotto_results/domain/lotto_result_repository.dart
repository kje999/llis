import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';

abstract class LottoResultRepository {
  Future<List<LottoResult>> getAll({int limit = 50, int offset = 0, int? lottoTypeId});
  Future<List<LottoResult>> getByDateRange({required int lottoTypeId, required String startDate, required String endDate});
  Future<LottoResult?> getById(int id);
  Future<LottoResult?> getLatestByTypeId(int lottoTypeId);
  Future<LottoResult?> findExisting(int lottoTypeId, String drawDate);
  Future<int> insert(LottoResult result);
  Future<void> update(LottoResult result);
  Future<void> delete(int id);
  Future<int> getTotalCount({int? lottoTypeId});
  Future<int> getCountThisYear();
}
