import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';

abstract class LottoTypeRepository {
  Future<List<LottoType>> getAll();
  Future<LottoType?> getById(int id);
  Future<LottoType?> getByCode(String code);
}
