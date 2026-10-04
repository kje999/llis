import '../../../shared/models/prediction_history.dart';

abstract class PredictionRepository {
  Future<List<PredictionHistory>> getByLottoTypeId(int lottoTypeId, {int limit = 10});
  Future<int> insert(PredictionHistory history);
}
