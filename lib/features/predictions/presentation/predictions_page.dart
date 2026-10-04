import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/features/predictions/domain/prediction_engine.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/statistical_suggestion_card.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_disclaimer_banner.dart';

class PredictionsPage extends StatefulWidget {
  const PredictionsPage({super.key});

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

class _PredictionsPageState extends State<PredictionsPage> {
  final PredictionEngine _predictionEngine = PredictionEngine();
  List<LottoType> _types = [];
  LottoType? _selectedType;
  List<StatisticalSuggestion> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    final typeRepo = context.read<LottoTypeRepository>();
    final types = await typeRepo.getAll();
    if (mounted) {
      setState(() {
        _types = types;
        if (types.isNotEmpty) {
          _selectedType = types.first;
        }
      });
      await _generateSuggestions();
    }
  }

  Future<void> _generateSuggestions() async {
    if (_selectedType == null) return;
    setState(() => _isLoading = true);

    final resultRepo = context.read<LottoResultRepository>();
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365)).toIso8601String().substring(0, 10);
    final today = now.toIso8601String().substring(0, 10);

    final historicalDraws = await resultRepo.getByDateRange(
      lottoTypeId: _selectedType!.id,
      startDate: oneYearAgo,
      endDate: today,
    );

    final suggestions = _predictionEngine.generateSuggestions(
      lottoType: _selectedType!,
      historicalDraws: historicalDraws,
      count: 5,
    );

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
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
            'Statistical Suggestion Engine',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Data-driven combinations ranked strictly by 1-year historical statistical scores with verifiable justifications.',
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
                  const Text('Select Game for Suggestions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            _generateSuggestions();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('RE-CALCULATE STATISTICAL SUGGESTIONS', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isLoading ? null : _generateSuggestions,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_suggestions.isEmpty)
            const Center(child: Text('No suggestions generated.'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return StatisticalSuggestionCard(
                  suggestion: _suggestions[index],
                  lottoTypeName: _selectedType?.name ?? 'PCSO Lotto',
                );
              },
            ),
        ],
      ),
    );
  }
}
