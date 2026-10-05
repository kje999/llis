import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/features/predictions/domain/prediction_engine.dart';
import 'package:intl/intl.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/pcso_game_rule_service.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/statistical_suggestion_card.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_disclaimer_banner.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_service.dart';

class PredictionsPage extends StatefulWidget {
  const PredictionsPage({super.key});

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

class _PredictionsPageState extends State<PredictionsPage> {
  static final Map<int, List<StatisticalSuggestion>> _cachedSuggestions = {};
  static final Map<int, LottoResult?> _cachedLatestDraws = {};

  final PredictionEngine _predictionEngine = PredictionEngine();
  List<LottoType> _types = [];
  LottoType? _selectedType;
  List<StatisticalSuggestion> _suggestions = [];
  LottoResult? _latestDraw;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    final typeRepo = context.read<LottoTypeRepository>();
    final types = await typeRepo.getAll();
    if (!mounted) return;

    setState(() {
      _types = types;
      if (types.isNotEmpty && _selectedType == null) {
        _selectedType = types.first;
      }
    });

    if (_selectedType != null) {
      if (_cachedSuggestions.containsKey(_selectedType!.id)) {
        setState(() {
          _suggestions = _cachedSuggestions[_selectedType!.id]!;
          _latestDraw = _cachedLatestDraws[_selectedType!.id];
          _isLoading = false;
        });
      } else {
        await _generateSuggestionsForType(_selectedType!, forceRecalculate: false);
      }
    }

    // Warm up the other games in background so switching between any games is instant with no loading
    for (final type in types) {
      if (type.id != _selectedType?.id && !_cachedSuggestions.containsKey(type.id)) {
        _generateSuggestionsForType(type, forceRecalculate: false, silent: true);
      }
    }
  }

  void _onGameTypeSelected(LottoType type) async {
    if (_selectedType?.id == type.id) return;

    setState(() {
      _selectedType = type;
    });

    if (_cachedSuggestions.containsKey(type.id)) {
      // Game suggestions already cached! Do NOT recalculate. Just show the existing cached suggestions.
      setState(() {
        _suggestions = _cachedSuggestions[type.id]!;
        _latestDraw = _cachedLatestDraws[type.id];
        _isLoading = false;
      });
      return;
    }

    // Not yet cached: calculate initial baseline suggestions once
    await _generateSuggestionsForType(type, forceRecalculate: false);
  }

  Future<void> _generateSuggestionsForType(
    LottoType type, {
    required bool forceRecalculate,
    bool silent = false,
  }) async {
    final isCurrent = _selectedType?.id == type.id;
    if (isCurrent && !silent) {
      setState(() => _isLoading = true);
    }

    final resultRepo = context.read<LottoResultRepository>();
    final syncService = context.read<SynchronizationService>();
    var latestDraw = await resultRepo.getLatestByTypeId(type.id);
    if (latestDraw == null) {
      await syncService.loadCachedResultsFromBackend();
      latestDraw = await resultRepo.getLatestByTypeId(type.id);
    }
    DateTime referenceDate = DateTime.now();
    if (latestDraw != null) {
      final parsed = DateTime.tryParse(latestDraw.drawDate);
      if (parsed != null && parsed.isAfter(referenceDate)) {
        referenceDate = parsed;
      }
    }
    final oneYearAgo = referenceDate
        .subtract(const Duration(days: 365))
        .toIso8601String()
        .substring(0, 10);
    final today = referenceDate
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    final historicalDraws = await resultRepo.getByDateRange(
      lottoTypeId: type.id,
      startDate: oneYearAgo,
      endDate: today,
    );

    // If initial calculation, use deterministic baseline seed based on type.id
    // If user explicitly pressed recalculate, use dynamic timestamp seed for new combinations
    final seed = forceRecalculate
        ? DateTime.now().microsecondsSinceEpoch
        : (type.id * 1000 + 42);

    final suggestions = _predictionEngine.generateSuggestions(
      lottoType: type,
      historicalDraws: historicalDraws,
      count: 5,
      seed: seed,
    );

    _cachedSuggestions[type.id] = suggestions;
    _cachedLatestDraws[type.id] = latestDraw;

    if (mounted && _selectedType?.id == type.id) {
      setState(() {
        _latestDraw = latestDraw;
        _suggestions = suggestions;
        _isLoading = false;
      });

      if (forceRecalculate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recalculated fresh statistical suggestions for ${type.name}!',
            ),
            backgroundColor: const Color(0xFF1E3A8A),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                    'Statistical Suggestion Engine',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.pcsoBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Data-driven combinations ranked strictly by 1-year historical statistical scores.',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Game for Suggestions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
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
                            _onGameTypeSelected(type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType != null) ...[
                    Builder(
                      builder: (context) {
                        final schedule = PcsoGameRuleService.getSchedule(
                          _selectedType!.code,
                        );
                        final nextDraw = schedule?.getNextDrawDate();
                        final prizes = PcsoGameRuleService.getPrizeTiersForGame(
                          _selectedType!.code,
                          dynamicJackpot: _latestDraw?.jackpotPrize,
                          drawDate: _latestDraw?.drawDate,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alarm_on,
                                    color: Color(0xFFFFB300),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Draw Reminder: ${schedule?.drawDaysText ?? ''} at 9:00 PM PHT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? Colors.white : AppTheme.pcsoBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (nextDraw != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Next official draw will be on ${DateFormat('EEEE, MMMM d, yyyy').format(nextDraw)}.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF60A5FA) : Colors.blue.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                'Winning Prize Categories: ${prizes.map((p) => '${p.tierName} (${p.matchCount}/6 matches)').join(' • ')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.blueGrey.shade800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.pcsoHeroGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.pcsoBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 20),
                        label: const Flexible(
                          child: Text(
                            'RE-CALCULATE SUGGESTIONS',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                          ),
                        ),
                        onPressed: _isLoading || _selectedType == null
                            ? null
                            : () => _generateSuggestionsForType(
                                _selectedType!,
                                forceRecalculate: true,
                              ),
                      ),
                    ),
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
                  lottoType: _selectedType,
                );
              },
            ),
        ],
      ),
    );
  }
}
