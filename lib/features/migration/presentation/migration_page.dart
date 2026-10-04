import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/core/database/database_executor.dart';
import 'package:my_lucky_lotto_pred/features/migration/domain/legacy_mysql_migrator.dart';

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  final _sqlTextController = TextEditingController(
    text: "-- Example Legacy MySQL SQL from VB.NET 2013 LLIS\n"
        "INSERT INTO `tbl_users` (`id`, `username`, `password`, `fullname`, `email`) VALUES\n"
        "(10, 'john_doe', 'pass1234', 'John Doe', 'john@example.com'),\n"
        "(11, 'maria_santos', 'maria2013', 'Maria Santos', 'maria@example.com');\n",
  );
  bool _isMigrating = false;
  MigrationReport? _report;

  Future<void> _startMigration() async {
    final text = _sqlTextController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isMigrating = true;
      _report = null;
    });

    final db = context.read<DatabaseExecutor>();
    final migrator = LegacyMySqlMigrator(db);
    final report = await migrator.migrateSqlDump(text);

    if (mounted) {
      setState(() {
        _isMigrating = false;
        _report = report;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legacy MySQL Database Migration',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Convert legacy VB.NET 2013 / MySQL database dumps directly into modern SQLite format with SHA-256 password re-hashing.',
            style: TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paste Legacy MySQL SQL Dump Content:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sqlTextController,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Paste SQL statements from Lucky Lotto Database MySQL folder...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    icon: _isMigrating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.transform),
                    label: const Text('PARSE & MIGRATE INTO SQLITE'),
                    onPressed: _isMigrating ? null : _startMigration,
                  ),
                  if (_report != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Legacy Migration Complete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('• Users imported & re-hashed: ${_report!.usersImported}'),
                          Text('• Historical draws converted: ${_report!.resultsImported}'),
                          Text('• Skipped / unhandled statements: ${_report!.skippedRecords}'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
