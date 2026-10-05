import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/features/analytics/domain/analytics_service.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_disclaimer_banner.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_service.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/save_pick_dialog.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsService _analyticsService = AnalyticsService();
  List<LottoType> _types = [];
  LottoType? _selectedType;
  String _selectedPeriod = 'Last 1 Year';
  AnalyticsResult? _analyticsResult;
  bool _isLoading = true;

  final List<String> _periodOptions = [
    'Last 30 Days',
    'Last 90 Days',
    'Last 6 Months',
    'Last 1 Year',
  ];

  @override
  void initState() {
    super.initState();
    _loadTypesAndAnalyze();
  }

  Future<void> _loadTypesAndAnalyze() async {
    final typeRepo = context.read<LottoTypeRepository>();
    final types = await typeRepo.getAll();
    if (mounted) {
      setState(() {
        _types = types;
        if (types.isNotEmpty && _selectedType == null) {
          _selectedType = types.first;
        }
      });
      await _runAnalysis();
    }
  }

  Future<void> _runAnalysis() async {
    if (_selectedType == null) return;
    setState(() => _isLoading = true);

    final resultRepo = context.read<LottoResultRepository>();
    final syncService = context.read<SynchronizationService>();

    var latestDraw = await resultRepo.getLatestByTypeId(_selectedType!.id);
    if (latestDraw == null) {
      await syncService.loadCachedResultsFromBackend();
      latestDraw = await resultRepo.getLatestByTypeId(_selectedType!.id);
    }

    int days = 365;
    if (_selectedPeriod == 'Last 30 Days') days = 30;
    if (_selectedPeriod == 'Last 90 Days') days = 90;
    if (_selectedPeriod == 'Last 6 Months') days = 180;

    DateTime referenceDate = DateTime.now();
    if (latestDraw != null) {
      final parsed = DateTime.tryParse(latestDraw.drawDate);
      if (parsed != null) {
        referenceDate = parsed;
      }
    }

    final startDate = referenceDate.subtract(Duration(days: days)).toIso8601String().substring(0, 10);
    final endDate = referenceDate.add(const Duration(days: 1)).toIso8601String().substring(0, 10);

    final draws = await resultRepo.getByDateRange(
      lottoTypeId: _selectedType!.id,
      startDate: startDate,
      endDate: endDate,
    );

    final result = _analyticsService.analyze(lottoType: _selectedType!, draws: draws);

    if (mounted) {
      setState(() {
        _analyticsResult = result;
        _isLoading = false;
      });
    }
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
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lotto Statistical Analytics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.pcsoBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Independent historical statistical breakdown per PCSO game (Strictly isolated by lotto type).',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LottoDisclaimerBanner(),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Game & Analysis Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types.map((type) {
                      final isSelected = _selectedType?.id == type.id;
                      return ChoiceChip(
                        label: Text(type.name),
                        selected: isSelected,
                        selectedColor: AppTheme.pcsoBlue.withValues(alpha: 0.15),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedType = type);
                            _runAnalysis();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Period: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPeriod,
                                items: _periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPeriod = val);
                                    _runAnalysis();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_analyticsResult != null && _analyticsResult!.hotNumbers.length >= 6 && _selectedType != null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pcsoBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.bookmark_add, size: 16, color: Color(0xFFFFB300)),
                          label: const Text('Use Hot Numbers as Pick', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () {
                            final top6 = _analyticsResult!.hotNumbers.take(6).map((n) => n.number).toList();
                            showSavePickConfirmationDialog(
                              context: context,
                              numbers: top6,
                              lottoType: _selectedType!,
                              sourceTitle: 'Top Hot Numbers Combination',
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_analyticsResult != null) ...[
            _buildHighlightsRow(_analyticsResult!, isDark),
            const SizedBox(height: 16),
            _buildFrequencyHeatmap(_analyticsResult!, isDark),
            const SizedBox(height: 16),
            _buildPairsAndTriplets(_analyticsResult!, isDark),
            const SizedBox(height: 16),
            _buildDistributionsCard(_analyticsResult!, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightsRow(AnalyticsResult res, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final hotBox = _buildStatBox(
          '🔥 HOT NUMBERS',
          'Top drawn numbers in selected period',
          res.hotNumbers.map((n) => LottoBall(number: n.number, size: 36)).toList(),
          isDark ? const Color(0xFF3F1B1B) : Colors.red.shade50,
          isDark ? const Color(0xFFFCA5A5) : Colors.red.shade800,
          isDark: isDark,
          trailingAction: res.hotNumbers.length >= 6 && _selectedType != null
              ? ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.bookmark_add, size: 14),
                  label: const Text('Use as Pick', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final top6 = res.hotNumbers.take(6).map((n) => n.number).toList();
                    showSavePickConfirmationDialog(
                      context: context,
                      numbers: top6,
                      lottoType: _selectedType!,
                      sourceTitle: 'Top Hot Numbers (${_selectedType!.name})',
                    );
                  },
                )
              : null,
        );

        final coldBox = _buildStatBox(
          '❄️ COLD NUMBERS',
          'Infrequently drawn numbers',
          res.coldNumbers.map((n) => LottoBall(number: n.number, size: 36)).toList(),
          isDark ? const Color(0xFF172554) : Colors.blue.shade50,
          isDark ? const Color(0xFF93C5FD) : Colors.blue.shade800,
          isDark: isDark,
        );

        final overdueBox = _buildStatBox(
          '⏳ OVERDUE NUMBERS',
          'Most draws since last appearance',
          res.overdueNumbers.map((n) => LottoBall(number: n.number, size: 36)).toList(),
          isDark ? const Color(0xFF3B2E15) : Colors.amber.shade50,
          isDark ? const Color(0xFFFCD34D) : Colors.amber.shade900,
          isDark: isDark,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: hotBox),
              const SizedBox(width: 12),
              Expanded(child: coldBox),
              const SizedBox(width: 12),
              Expanded(child: overdueBox),
            ],
          );
        } else {
          return Column(
            children: [
              hotBox,
              const SizedBox(height: 12),
              coldBox,
              const SizedBox(height: 12),
              overdueBox,
            ],
          );
        }
      },
    );
  }

  Widget _buildStatBox(
    String title,
    String subtitle,
    List<Widget> balls,
    Color bg,
    Color textCol, {
    Widget? trailingAction,
    required bool isDark,
  }) {
    return Card(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700)),
                  ],
                ),
                if (trailingAction != null) trailingAction,
              ],
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: balls),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyHeatmap(AnalyticsResult res, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text('Number Frequency Heatmap & Counts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Total Draws: ${res.totalDrawsAnalyzed}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: res.allFrequencies.map((f) {
                return Tooltip(
                  message: 'Number ${f.number}: drawn ${f.count} times (${f.percentage.toStringAsFixed(1)}%)\nDraws since last: ${f.drawsSince}',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    ),
                    child: Column(
                      children: [
                        LottoBall(number: f.number, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          '${f.count}x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairsAndTriplets(AnalyticsResult res, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Most Frequent Number Pairs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: res.topPairs.map((pair) {
                return Chip(
                  avatar: const Icon(Icons.link, size: 16, color: Color(0xFFFFB300)),
                  label: Text('${pair.label} (${pair.count} draws)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.blue.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionsCard(AnalyticsResult res, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Draw Distribution & Sum Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 750;

                final col1 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Odd / Even Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...res.oddEvenDistribution.take(4).map((d) => Text('• ${d.pattern}: ${d.percentage.toStringAsFixed(1)}% (${d.occurrences} draws)', style: const TextStyle(fontSize: 12))),
                  ],
                );

                final col2 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Low / High Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...res.lowHighDistribution.take(4).map((d) => Text('• ${d.pattern}: ${d.percentage.toStringAsFixed(1)}% (${d.occurrences} draws)', style: const TextStyle(fontSize: 12))),
                  ],
                );

                final col3 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Historical Combination Sum:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('• Typical Sum Range: ${res.sumStatistics.commonRange}', style: const TextStyle(fontSize: 12)),
                    Text('• Average Sum: ${res.sumStatistics.avgSum.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
                    Text('• Min / Max Sum: ${res.sumStatistics.minSum} / ${res.sumStatistics.maxSum}', style: const TextStyle(fontSize: 12)),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: col1),
                      const SizedBox(width: 16),
                      Expanded(child: col2),
                      const SizedBox(width: 16),
                      Expanded(child: col3),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      col1,
                      const Divider(height: 24),
                      col2,
                      const Divider(height: 24),
                      col3,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
