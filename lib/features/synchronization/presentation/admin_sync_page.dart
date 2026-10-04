import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_service.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/synchronization_log.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';

class AdminSyncPage extends StatefulWidget {
  const AdminSyncPage({super.key});

  @override
  State<AdminSyncPage> createState() => _AdminSyncPageState();
}

class _AdminSyncPageState extends State<AdminSyncPage> {
  // Date combo box values: From Date (default 1 year ago) & To Date (default today)
  late int _fromMonth;
  late int _fromDay;
  late int _fromYear;

  late int _toMonth;
  late int _toDay;
  late int _toYear;

  String _selectedGame = 'ALL';
  bool _isSyncing = false;
  SyncSummary? _lastSummary;
  List<SynchronizationLog> _logs = [];
  List<LottoResult> _scrapedResultsPreview = [];
  int _totalStoredCount = 0;
  int _currentPage = 1;
  int _pageSize = 25;
  bool _showHtmlPaste = false;
  final TextEditingController _htmlPasteController = TextEditingController();
  List<String> _backendConsoleLogs = [];
  bool _isLoadingBackendLogs = false;

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<Map<String, String>> _gameOptions = [
    {'code': 'ALL', 'label': 'All Games (5 Supported)'},
    {'code': 'ULTRA_6_58', 'label': 'Ultra Lotto 6/58'},
    {'code': 'GRAND_6_55', 'label': 'Grand Lotto 6/55'},
    {'code': 'SUPER_6_49', 'label': 'Super Lotto 6/49'},
    {'code': 'MEGA_6_45', 'label': 'Mega Lotto 6/45'},
    {'code': 'LOTTO_6_42', 'label': 'Lotto 6/42'},
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default: 1 Year Range (e.g. October 2025 to October 2026)
    final oneYearAgo = now.subtract(const Duration(days: 365));

    _fromMonth = oneYearAgo.month;
    _fromDay = oneYearAgo.day;
    _fromYear = oneYearAgo.year;

    _toMonth = now.month;
    _toDay = now.day;
    _loadLogs();
    _loadExistingDraws();
    _fetchBackendLogs();
  }

  Future<void> _fetchBackendLogs() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:8081/api/sync/logs')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['logs'] is List) {
          if (mounted) {
            setState(() {
              _backendConsoleLogs = List<String>.from(data['logs']);
            });
          }
        }
      }
    } catch (_) {
      // Backend service might not be running or is loading
    }
  }

  Future<void> _loadExistingDraws() async {
    final resultRepo = context.read<LottoResultRepository>();
    final total = await resultRepo.getTotalCount();
    final offset = (_currentPage - 1) * _pageSize;
    final draws = await resultRepo.getAll(limit: _pageSize, offset: offset);
    if (mounted) {
      setState(() {
        _totalStoredCount = total;
        _scrapedResultsPreview = draws;
      });
    }
  }

  @override
  void dispose() {
    _htmlPasteController.dispose();
    super.dispose();
  }

  DateTime get _fromDate => DateTime(_fromYear, _fromMonth, _fromDay);
  DateTime get _toDate => DateTime(_toYear, _toMonth, _toDay, 23, 59, 59);

  void _applyPreset(int daysAgo) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysAgo));
    setState(() {
      _fromYear = start.year;
      _fromMonth = start.month;
      _fromDay = start.day;

      _toYear = now.year;
      _toMonth = now.month;
      _toDay = now.day;
    });
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

    final summary = await service.synchronize(
      fromDate: _fromDate,
      toDate: _toDate,
      selectedGameCode: _selectedGame,
      rawHtmlContent:
          _showHtmlPaste && _htmlPasteController.text.trim().isNotEmpty
          ? _htmlPasteController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSummary = summary;
        _currentPage = 1; // Reset to first page
      });
      await _loadExistingDraws();
      await _loadLogs();
      await _fetchBackendLogs();
    }
  }

  Future<void> _confirmClearAllResults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Results?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all official lotto draw results from the database?\n\nThis will clear your local results and reset the central synchronization cache. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All Results'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSyncing = true);
      final resultRepo = context.read<LottoResultRepository>();
      await resultRepo.deleteAll();

      // Also tell backend service to clear central cache if active
      try {
        await http.post(Uri.parse('http://localhost:8081/api/sync/clear')).timeout(const Duration(seconds: 2));
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSyncing = false;
          _scrapedResultsPreview = [];
          _totalStoredCount = 0;
          _currentPage = 1;
          _lastSummary = null;
        });
        await _fetchBackendLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All official lotto draw results have been cleared successfully.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Official PCSO Web Scraping & Synchronization',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Search, scrape, validate, and synchronize official draw results directly from PCSO portal.',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: Icon(_showHtmlPaste ? Icons.close : Icons.code, size: 16),
                label: Text(
                  _showHtmlPaste
                      ? 'Hide HTML Importer'
                      : 'Direct HTML/Text Table Import',
                ),
                onPressed: () =>
                    setState(() => _showHtmlPaste = !_showHtmlPaste),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Direct HTML Paste Card (if enabled)
          if (_showHtmlPaste) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.amber.shade50.withValues(alpha: 0.5),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.terminal, color: Color(0xFF1E3A8A)),
                        SizedBox(width: 8),
                        Text(
                          'Direct PCSO Portal HTML / Tabular Paste (CORS Bypass)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Paste raw HTML source or copied table text from https://www.pcso.gov.ph/searchlottoresult.aspx to parse games, numbers, draw dates, jackpots, and winners count directly.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _htmlPasteController,
                      maxLines: 5,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Paste <table> content or lines like: Ultra Lotto 6/58  10-48-11-15-46-26  10/4/2026  361,488,985.19  0',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // PCSO Web Interface Controls Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          color: Color(0xFF1E3A8A),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search Lotto Draw Result by Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          Text(
                            'Set the Start Date and End Date of Lotto Draw and select from the list of Lotto games below to view & synchronize results:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // Quick Presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Presets: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.history, size: 14),
                        label: const Text('1 Year History (Recommended)'),
                        onPressed: () => _applyPreset(365),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.calendar_month, size: 14),
                        label: const Text('Last 6 Months'),
                        onPressed: () => _applyPreset(180),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.date_range, size: 14),
                        label: const Text('Last 30 Days'),
                        onPressed: () => _applyPreset(30),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.today, size: 14),
                        label: const Text('Today (Oct 4, 2026)'),
                        onPressed: () => _applyPreset(0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // From Date / To Date Combo Boxes
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Set Draw Date Row
                          if (!isMobile)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 130,
                                  child: Text(
                                    'Set Draw Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'From: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildDateDropdowns(
                                  selectedMonth: _fromMonth,
                                  selectedDay: _fromDay,
                                  selectedYear: _fromYear,
                                  onMonthChanged: (m) =>
                                      setState(() => _fromMonth = m),
                                  onDayChanged: (d) =>
                                      setState(() => _fromDay = d),
                                  onYearChanged: (y) =>
                                      setState(() => _fromYear = y),
                                ),
                                const SizedBox(width: 24),
                                const Text(
                                  'To: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildDateDropdowns(
                                  selectedMonth: _toMonth,
                                  selectedDay: _toDay,
                                  selectedYear: _toYear,
                                  onMonthChanged: (m) =>
                                      setState(() => _toMonth = m),
                                  onDayChanged: (d) =>
                                      setState(() => _toDay = d),
                                  onYearChanged: (y) =>
                                      setState(() => _toYear = y),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Set Draw Date From:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildDateDropdowns(
                                  selectedMonth: _fromMonth,
                                  selectedDay: _fromDay,
                                  selectedYear: _fromYear,
                                  onMonthChanged: (m) =>
                                      setState(() => _fromMonth = m),
                                  onDayChanged: (d) =>
                                      setState(() => _fromDay = d),
                                  onYearChanged: (y) =>
                                      setState(() => _fromYear = y),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Set Draw Date To:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildDateDropdowns(
                                  selectedMonth: _toMonth,
                                  selectedDay: _toDay,
                                  selectedYear: _toYear,
                                  onMonthChanged: (m) =>
                                      setState(() => _toMonth = m),
                                  onDayChanged: (d) =>
                                      setState(() => _toDay = d),
                                  onYearChanged: (y) =>
                                      setState(() => _toYear = y),
                                ),
                              ],
                            ),
                          const SizedBox(height: 18),

                          // Select Lotto Game
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: isMobile ? 120 : 130,
                                child: const Text(
                                  'Select Lotto Game',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedGame,
                                    items: _gameOptions.map((g) {
                                      return DropdownMenuItem<String>(
                                        value: g['code'],
                                        child: Text(
                                          g['label']!,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null)
                                        setState(() => _selectedGame = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons Row: Search & Clear
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search, size: 20),
                        label: Text(
                          _isSyncing
                              ? 'SCRAPING & SYNCHRONIZING...'
                              : 'SEARCH & SCRAPE PCSO',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: _isSyncing ? null : _runSync,
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade400),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                        label: const Text(
                          'CLEAR ALL RESULTS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: _isSyncing ? null : _confirmClearAllResults,
                      ),
                    ],
                  ),

                  // Sync Summary Feedback
                  if (_lastSummary != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lastSummary!.status == 'SUCCESS'
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lastSummary!.status == 'SUCCESS'
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _lastSummary!.status == 'SUCCESS'
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _lastSummary!.status == 'SUCCESS'
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Webscraping Synchronization ${_lastSummary!.status}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _lastSummary!.status == 'SUCCESS'
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildMetricChip(
                                'Found',
                                _lastSummary!.recordsFound.toString(),
                                Colors.blue,
                              ),
                              _buildMetricChip(
                                'Inserted',
                                _lastSummary!.recordsInserted.toString(),
                                Colors.green,
                              ),
                              _buildMetricChip(
                                'Updated',
                                _lastSummary!.recordsUpdated.toString(),
                                Colors.orange,
                              ),
                              _buildMetricChip(
                                'Skipped/Existing',
                                _lastSummary!.recordsSkipped.toString(),
                                Colors.grey,
                              ),
                            ],
                          ),
                          if (_lastSummary!.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Notice: ${_lastSummary!.errorMessage}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Live Backend Worker Console Stream
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.terminal, color: Color(0xFF38BDF8), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Backend Synchronization Worker Terminal (Port 8081)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
                              tooltip: 'Refresh Terminal Output',
                              onPressed: _fetchBackendLogs,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF334155), height: 16),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 140),
                          child: _backendConsoleLogs.isEmpty
                              ? const Text(
                                  '[INFO] Waiting for backend worker activity... (Start via run_backend_sync.bat or click SEARCH & SCRAPE PCSO)',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _backendConsoleLogs.length,
                                  itemBuilder: (context, idx) {
                                    final log = _backendConsoleLogs[idx];
                                    final isError = log.contains('ERROR') || log.contains('403');
                                    final isSuccess = log.contains('SUCCESS') || log.contains('Complete') || log.contains('ready');
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                                      child: Text(
                                        log,
                                        style: TextStyle(
                                          color: isError
                                              ? const Color(0xFFF87171)
                                              : isSuccess
                                                  ? const Color(0xFF4ADE80)
                                                  : const Color(0xFF94A3B8),
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Official Results Table Preview (Matching PCSO Search Results layout)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Search Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              '$_totalStoredCount Total Synchronized Draw(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Rows per page: ',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                          ),
                          DropdownButton<int>(
                            value: _pageSize,
                            underline: const SizedBox(),
                            isDense: true,
                            items: [20, 25, 50, 100].map((int val) {
                              return DropdownMenuItem<int>(
                                value: val,
                                child: Text('$val', style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (newSize) {
                              if (newSize != null) {
                                setState(() {
                                  _pageSize = newSize;
                                  _currentPage = 1;
                                });
                                _loadExistingDraws();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_scrapedResultsPreview.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.table_rows_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No draw results in database yet. Click "SEARCH & SCRAPE PCSO" above to synchronize.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFF1E3A8A),
                        ),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        columns: const [
                          DataColumn(label: Text('LOTTO GAME')),
                          DataColumn(label: Text('COMBINATIONS')),
                          DataColumn(label: Text('DRAW DATE')),
                          DataColumn(label: Text('JACKPOT (PHP)')),
                          DataColumn(label: Text('WINNERS')),
                        ],
                        rows: _scrapedResultsPreview.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  r.lottoTypeName ?? 'PCSO Lotto',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Wrap(
                                  spacing: 4,
                                  children: r.numbers
                                      .map(
                                        (n) => LottoBall(number: n, size: 28),
                                      )
                                      .toList(),
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.drawDate,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.formattedJackpot,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: r.winners > 0
                                        ? Colors.amber.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: r.winners > 0
                                          ? Colors.amber.shade300
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    r.winners.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: r.winners > 0
                                          ? Colors.brown.shade900
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  if (_scrapedResultsPreview.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${((_currentPage - 1) * _pageSize) + 1} to ${((_currentPage - 1) * _pageSize) + _scrapedResultsPreview.length} of $_totalStoredCount draws',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.chevron_left, size: 16),
                              label: const Text('Previous', style: TextStyle(fontSize: 12)),
                              onPressed: _currentPage > 1
                                  ? () {
                                      setState(() => _currentPage--);
                                      _loadExistingDraws();
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Page $_currentPage of ${(_totalStoredCount / _pageSize).ceil() == 0 ? 1 : (_totalStoredCount / _pageSize).ceil()}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              label: const Text('Next', style: TextStyle(fontSize: 12)),
                              icon: const Icon(Icons.chevron_right, size: 16),
                              onPressed: (_currentPage * _pageSize) < _totalStoredCount
                                  ? () {
                                      setState(() => _currentPage++);
                                      _loadExistingDraws();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Audit Logs
          const Text(
            'Recent Synchronization Audit Logs',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No synchronization logs recorded yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final l = _logs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: l.status == 'SUCCESS'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        l.status == 'SUCCESS' ? Icons.check : Icons.error,
                        color: l.status == 'SUCCESS'
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sync Status: ${l.status}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Found: ${l.recordsFound} | Inserted: ${l.recordsInserted} | Updated: ${l.recordsUpdated} | Skipped: ${l.recordsSkipped}\n'
                      'Started: ${DateFormat('yyyy-MM-dd HH:mm').format(l.startedAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      '${l.completedAt.difference(l.startedAt).inSeconds}s',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
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

  Widget _buildDateDropdowns({
    required int selectedMonth,
    required int selectedDay,
    required int selectedYear,
    required Function(int) onMonthChanged,
    required Function(int) onDayChanged,
    required Function(int) onYearChanged,
  }) {
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Month combo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedMonth,
              items: List.generate(12, (i) => i + 1).map((m) {
                return DropdownMenuItem<int>(
                  value: m,
                  child: Text(
                    _months[m - 1],
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onMonthChanged(val);
              },
            ),
          ),
        ),
        // Day combo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedDay,
              items: List.generate(31, (i) => i + 1).map((d) {
                return DropdownMenuItem<int>(
                  value: d,
                  child: Text(
                    d.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onDayChanged(val);
              },
            ),
          ),
        ),
        // Year combo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedYear,
              items: [2024, 2025, 2026, 2027].map((y) {
                return DropdownMenuItem<int>(
                  value: y,
                  child: Text(
                    y.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onYearChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
