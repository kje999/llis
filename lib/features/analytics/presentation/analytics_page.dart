import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/features/analytics/domain/analytics_service.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_disclaimer_banner.dart';

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

    int days = 365;
    if (_selectedPeriod == 'Last 30 Days') days = 30;
    if (_selectedPeriod == 'Last 90 Days') days = 90;
    if (_selectedPeriod == 'Last 6 Months') days = 180;

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days)).toIso8601String().substring(0, 10);
    final endDate = now.toIso8601String().substring(0, 10);

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lotto Statistical Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Independent historical statistical breakdown per PCSO game (Strictly isolated by lotto type).',
            style: TextStyle(fontSize: 13, color: Colors.blueGrey),
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
                        selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedType = type);
                            _runAnalysis();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Period: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items: _periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPeriod = val);
                            _runAnalysis();
                          }
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
            const Center(child: CircularProgressIndicator())
          else if (_analyticsResult != null) ...[
            _buildHighlightsRow(_analyticsResult!),
            const SizedBox(height: 16),
            _buildFrequencyHeatmap(_analyticsResult!),
            const SizedBox(height: 16),
            _buildPairsAndTriplets(_analyticsResult!),
            const SizedBox(height: 16),
            _buildDistributionsCard(_analyticsResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightsRow(AnalyticsResult res) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final children = [
          Expanded(
            flex: isWide ? 1 : 0,
            child: _buildStatBox(
              '🔥 HOT NUMBERS',
              'Top drawn numbers in selected period',
              res.hotNumbers.map((n) => LottoBall(number: n.number, size: 36)).toList(),
              Colors.red.shade50,
              Colors.red.shade800,
            ),
          ),
          SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
          Expanded(
            flex: isWide ? 1 : 0,
            child: _buildStatBox(
              '❄️ COLD NUMBERS',
              'Infrequently drawn numbers',
              res.coldNumbers.map((n) => LottoBall(number: n.number, size: 36)).toList(),
              Colors.blue.shade50,
              Colors.blue.shade800,
            ),
          ),
          SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
          Expanded(
            flex: isWide ? 1 : 0,
            child: _buildStatBox(
              '⏳ OVERDUE NUMBERS',
              'Most draws since last appearance',
              res.overdueNumbers.map((n) => LottoBall(number: n.number, size: 36)).toList(),
              Colors.amber.shade50,
              Colors.amber.shade900,
            ),
          ),
        ];

        return isWide ? Row(children: children) : Column(children: children);
      },
    );
  }

  Widget _buildStatBox(String title, String subtitle, List<Widget> balls, Color bg, Color textCol) {
    return Card(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Wrap(spacing: 4, runSpacing: 6, children: balls),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyHeatmap(AnalyticsResult res) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        LottoBall(number: f.number, size: 32),
                        const SizedBox(height: 4),
                        Text('${f.count}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
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

  Widget _buildPairsAndTriplets(AnalyticsResult res) {
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
              spacing: 12,
              runSpacing: 10,
              children: res.topPairs.map((pair) {
                return Chip(
                  avatar: const Icon(Icons.link, size: 16, color: Color(0xFF1E3A8A)),
                  label: Text('${pair.label} (${pair.count} draws)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  backgroundColor: Colors.blue.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionsCard(AnalyticsResult res) {
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Odd / Even Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...res.oddEvenDistribution.take(4).map((d) => Text('• ${d.pattern}: ${d.percentage.toStringAsFixed(1)}% (${d.occurrences} draws)', style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Low / High Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...res.lowHighDistribution.take(4).map((d) => Text('• ${d.pattern}: ${d.percentage.toStringAsFixed(1)}% (${d.occurrences} draws)', style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Historical Combination Sum:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('• Typical Sum Range: ${res.sumStatistics.commonRange}', style: const TextStyle(fontSize: 12)),
                      Text('• Average Sum: ${res.sumStatistics.avgSum.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
                      Text('• Min / Max Sum: ${res.sumStatistics.minSum} / ${res.sumStatistics.maxSum}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
