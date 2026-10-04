import 'package:my_lucky_lotto_pred/shared/models/prediction_history.dart';

abstract class PredictionRepository {
  Future<List<PredictionHistory>> getByLottoTypeId(int lottoTypeId, {int limit = 10});
  Future<int> insert(PredictionHistory history);
}
