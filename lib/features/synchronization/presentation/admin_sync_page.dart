import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/synchronization_service.dart';
import '../domain/synchronization_repository.dart';
import '../../shared/models/synchronization_log.dart';

class AdminSyncPage extends StatefulWidget {
  const AdminSyncPage({super.key});

  @override
  State<AdminSyncPage> createState() => _AdminSyncPageState();
}

class _AdminSyncPageState extends State<AdminSyncPage> {
  bool _isSyncing = false;
  SyncSummary? _lastSummary;
  List<SynchronizationLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final repo = context.read<SynchronizationRepository>();
    final logs = await repo.getAllLogs(limit: 15);
    if (mounted) {
      setState(() => _logs = logs);
    }
  }

  Future<void> _runSync() async {
    setState(() {
      _isSyncing = true;
      _lastSummary = null;
    });

    final service = context.read<SynchronizationService>();
    final summary = await service.synchronize();

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSummary = summary;
      });
      await _loadLogs();
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
            'Official PCSO Synchronization',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Retrieve, parse, validate, and store latest results from PCSO (https://www.pcso.gov.ph/searchlottoresult.aspx).',
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
                  const Text('Manual Synchronization Trigger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'Executes full pipeline: Scrape PCSO HTML -> Parse 6 numbers -> Validate range (e.g. 1..58) -> '
                    'Deduplicate by lotto_type & draw_date -> Insert/Update SQLite -> Notify affected users.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSyncing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: Text(_isSyncing ? 'SYNCHRONIZING PCSO RESULTS...' : 'SYNC NOW (EXECUTE PIPELINE)'),
                    onPressed: _isSyncing ? null : _runSync,
                  ),
                  if (_lastSummary != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _lastSummary!.status == 'SUCCESS' ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _lastSummary!.status == 'SUCCESS' ? Colors.green.shade300 : Colors.red.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _lastSummary!.status == 'SUCCESS' ? Icons.check_circle : Icons.error,
                                color: _lastSummary!.status == 'SUCCESS' ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Synchronization ${_lastSummary!.status}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _lastSummary!.status == 'SUCCESS' ? Colors.green.shade900 : Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Found: ${_lastSummary!.recordsFound} | Inserted: ${_lastSummary!.recordsInserted} | Updated: ${_lastSummary!.recordsUpdated} | Skipped/Deduplicated: ${_lastSummary!.recordsSkipped}'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Synchronization Audit Logs', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(
                    log.status == 'SUCCESS' ? Icons.done : Icons.error,
                    color: log.status == 'SUCCESS' ? Colors.green : Colors.red,
                  ),
                  title: Text('Sync #${log.id} - ${log.status} (Found: ${log.recordsFound}, New: ${log.recordsInserted}, Skipped: ${log.recordsSkipped})'),
                  subtitle: Text('Executed: ${log.startedAt.toLocal().toString().substring(0, 19)} | Source: ${log.sourceUrl}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.status == 'SUCCESS' ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: log.status == 'SUCCESS' ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
