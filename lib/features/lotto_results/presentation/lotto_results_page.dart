import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_result_card.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_service.dart';

class LottoResultsPage extends StatefulWidget {
  const LottoResultsPage({super.key});

  @override
  State<LottoResultsPage> createState() => _LottoResultsPageState();
}

class _LottoResultsPageState extends State<LottoResultsPage> {
  List<LottoType> _types = [];
  int? _selectedTypeId;
  List<LottoResult> _results = [];
  bool _isLoading = true;

  // Pagination Configuration: Minimum 20 results per page
  static const int _pageSize = 20;
  int _currentPage = 1;
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceSync = false}) async {
    final typeRepo = context.read<LottoTypeRepository>();
    final resultRepo = context.read<LottoResultRepository>();
    final syncService = context.read<SynchronizationService>();

    var total = await resultRepo.getTotalCount(lottoTypeId: _selectedTypeId);
    if (total == 0 || forceSync) {
      await syncService.loadCachedResultsFromBackend();
      total = await resultRepo.getTotalCount(lottoTypeId: _selectedTypeId);
    }

    final types = await typeRepo.getAll();
    final offset = (_currentPage - 1) * _pageSize;
    // Guaranteed sorted descending by date (recent and latest top)
    final results = await resultRepo.getAll(
      limit: _pageSize,
      offset: offset,
      lottoTypeId: _selectedTypeId,
    );

    if (mounted) {
      setState(() {
        _types = types;
        _totalRecords = total;
        _results = results;
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int newPage) {
    if (newPage < 1 || newPage > _totalPages) return;
    setState(() {
      _currentPage = newPage;
      _isLoading = true;
    });
    _loadData();
  }

  int get _totalPages {
    if (_totalRecords == 0) return 1;
    return (_totalRecords / _pageSize).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Official PCSO Draw Results',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.pcsoBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Historical draw results sorted from most recent to oldest (20 per page).',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pcsoBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh, size: 18, color: Color(0xFFFFB300)),
                label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadData(forceSync: true);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Game Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All 5 Lotto Games'),
                  selected: _selectedTypeId == null,
                  selectedColor: AppTheme.pcsoBlue.withValues(alpha: 0.15),
                  onSelected: (val) {
                    setState(() {
                      _selectedTypeId = null;
                      _currentPage = 1;
                      _isLoading = true;
                    });
                    _loadData();
                  },
                ),
                const SizedBox(width: 8),
                ..._types.map((type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.name),
                        selected: _selectedTypeId == type.id,
                        selectedColor: AppTheme.pcsoBlue.withValues(alpha: 0.15),
                        onSelected: (val) {
                          setState(() {
                            _selectedTypeId = val ? type.id : null;
                            _currentPage = 1;
                            _isLoading = true;
                          });
                          _loadData();
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Results Count & Page Information Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort, size: 18, color: Color(0xFFFFB300)),
                    const SizedBox(width: 8),
                    Text(
                      'Showing ${((_currentPage - 1) * _pageSize) + 1}–${(((_currentPage - 1) * _pageSize) + _results.length).clamp(0, _totalRecords)} of $_totalRecords results',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppTheme.pcsoBlue,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No draw results found for selected filter.', style: TextStyle(color: Colors.grey.shade600)),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                return LottoResultCard(result: _results[index]);
              },
            ),
            const SizedBox(height: 20),
            // Bottom Pagination Controls
            _buildPaginationControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Previous 20'),
            onPressed: _currentPage > 1 ? () => _onPageChanged(_currentPage - 1) : null,
          ),
          // Page Indicator & Numbers
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 8),
              Text(
                '(20 items/page)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          // Next Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Next 20'),
            onPressed: _currentPage < _totalPages ? () => _onPageChanged(_currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}
