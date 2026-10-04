import 'database_executor.dart';
import 'in_memory_database_executor.dart';

DatabaseExecutor createNativeDatabase() {
  return InMemoryDatabaseExecutor();
}
