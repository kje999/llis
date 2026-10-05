import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/core/services/text_to_speech_service.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/shared/models/lucky_pick.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_service.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_disclaimer_banner.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/pcso_game_rule_service.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_service.dart';

enum LuckyPickMode { autoGenerator, manualPlayslip }

class LuckyPickPage extends StatefulWidget {
  const LuckyPickPage({super.key});

  @override
  State<LuckyPickPage> createState() => _LuckyPickPageState();
}

class _LuckyPickPageState extends State<LuckyPickPage> {
  final LuckyPickService _pickService = LuckyPickService();
  List<LottoType> _lottoTypes = [];
  LottoType? _selectedType;
  LuckyPickMode _mode = LuckyPickMode.autoGenerator;

  // Auto Generator state
  List<int> _generatedNumbers = [];

  // Manual Playslip Shading state
  final Set<int> _manualSelectedNumbers = {};

  // Recent official draw results cache for dynamic jackpot display
  final Map<int, LottoResult?> _latestResultsCache = {};

  DateTime _selectedDrawDate = DateTime.now();
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadLottoTypes();
  }

  Future<void> _loadLottoTypes() async {
    final typeRepo = context.read<LottoTypeRepository>();
    final types = await typeRepo.getAll();
    if (mounted) {
      setState(() {
        _lottoTypes = types;
        if (types.isNotEmpty) {
          _selectedType = types.first;
          final sched = PcsoGameRuleService.getSchedule(types.first.code);
          if (sched != null) {
            _selectedDrawDate = sched.getNextDrawDate();
          }
        }
      });
      await _loadLatestResults();
    }
  }

  Future<void> _loadLatestResults() async {
    final resultRepo = context.read<LottoResultRepository>();
    final syncService = context.read<SynchronizationService>();
    final cache = <int, LottoResult?>{};

    for (final type in _lottoTypes) {
      var latest = await resultRepo.getLatestByTypeId(type.id);
      if (latest == null) {
        await syncService.loadCachedResultsFromBackend();
        latest = await resultRepo.getLatestByTypeId(type.id);
      }
      cache[type.id] = latest;
    }

    if (mounted) {
      setState(() {
        _latestResultsCache.addAll(cache);
      });
    }
  }

  void _generateNumbers() {
    if (_selectedType == null) return;
    final numbers = _pickService.generateNumbers(_selectedType!);
    setState(() {
      _generatedNumbers = numbers;
      _message = null;
    });

    final speech = 'Your lucky numbers are ${TextToSpeechService.formatSpokenNumbers(numbers)}.';
    TextToSpeechService.instance.speak(speech);
  }

  void _toggleManualNumber(int n) {
    setState(() {
      if (_manualSelectedNumbers.contains(n)) {
        _manualSelectedNumbers.remove(n);
        _message = null;
      } else {
        if (_manualSelectedNumbers.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already selected 6 numbers. Tap a shaded number to deselect it first.'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _manualSelectedNumbers.add(n);
        _message = null;
      }
    });
  }

  void _quickFillRemaining() {
    if (_selectedType == null) return;
    final random = Random();
    final maxNum = _selectedType!.maxNumber;
    final available = List.generate(maxNum, (i) => i + 1)
        .where((n) => !_manualSelectedNumbers.contains(n))
        .toList();
    available.shuffle(random);

    setState(() {
      while (_manualSelectedNumbers.length < 6 && available.isNotEmpty) {
        _manualSelectedNumbers.add(available.removeLast());
      }
      _message = null;
    });
  }

  void _clearManualSelection() {
    setState(() {
      _manualSelectedNumbers.clear();
      _message = null;
    });
  }

  Future<void> _saveCurrentPick(List<int> numbersToSave, String sourceLabel) async {
    if (_selectedType == null || numbersToSave.length != 6) return;
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;

    setState(() => _isSaving = true);
    final sorted = List<int>.from(numbersToSave)..sort();
    final pickRepo = context.read<LuckyPickRepository>();
    final newPick = LuckyPick(
      id: 0,
      userId: auth.currentUser!.id,
      lottoTypeId: _selectedType!.id,
      drawDate: DateFormat('yyyy-MM-dd').format(_selectedDrawDate),
      number1: sorted[0],
      number2: sorted[1],
      number3: sorted[2],
      number4: sorted[3],
      number5: sorted[4],
      number6: sorted[5],
      generatedAt: DateTime.now(),
      isChecked: false,
      matchCount: 0,
      status: 'PENDING',
    );

    await pickRepo.insert(newPick, username: auth.currentUser!.username);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _message = '$sourceLabel (${sorted.map((e) => e.toString().padLeft(2, '0')).join("-")}) saved successfully for ${DateFormat('MMMM d, yyyy').format(_selectedDrawDate)}!';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved combination ${sorted.map((e) => e.toString().padLeft(2, '0')).join("-")} to My Lucky Picks!'),
          backgroundColor: AppTheme.pcsoBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lucky Pick & Manual Playslip',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.pcsoBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Generate random combinations or shade your favorite 6 numbers on an official PCSO-style playslip.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
              // Segmented Mode Selector
              SegmentedButton<LuckyPickMode>(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.pcsoBlue.withValues(alpha: 0.15);
                    }
                    return null;
                  }),
                ),
                segments: const [
                  ButtonSegment(
                    value: LuckyPickMode.autoGenerator,
                    icon: Icon(Icons.casino_outlined, size: 18),
                    label: Text('Quick Pick Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  ButtonSegment(
                    value: LuckyPickMode.manualPlayslip,
                    icon: Icon(Icons.edit_note, size: 18),
                    label: Text('Manual Playslip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (newVal) {
                  setState(() {
                    _mode = newVal.first;
                    _message = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LottoDisclaimerBanner(),
          const SizedBox(height: 16),

          // Game Selector Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select PCSO Game', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _lottoTypes.map((type) {
                      final isSelected = _selectedType?.id == type.id;
                      return ChoiceChip(
                        label: Text(type.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedType = type;
                              final sched = PcsoGameRuleService.getSchedule(type.code);
                              if (sched != null) {
                                _selectedDrawDate = sched.getNextDrawDate();
                              }
                              _generatedNumbers = [];
                              // Prune manual numbers exceeding game max
                              _manualSelectedNumbers.removeWhere((n) => n > type.maxNumber);
                              _message = null;
                            });
                            if (!_latestResultsCache.containsKey(type.id) || _latestResultsCache[type.id] == null) {
                              context.read<LottoResultRepository>().getLatestByTypeId(type.id).then((res) {
                                if (mounted && res != null) {
                                  setState(() {
                                    _latestResultsCache[type.id] = res;
                                  });
                                }
                              });
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType != null) ...[
                    Builder(
                      builder: (context) {
                        final schedule = PcsoGameRuleService.getSchedule(_selectedType!.code);
                        final nextDraw = schedule?.getNextDrawDate();
                        final latestDraw = _latestResultsCache[_selectedType!.id];
                        final prizes = PcsoGameRuleService.getPrizeTiersForGame(
                          _selectedType!.code,
                          dynamicJackpot: latestDraw?.jackpotPrize,
                          drawDate: latestDraw?.drawDate,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Draw Schedule & Countdown Reminder Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.alarm_on, color: Color(0xFFFFB300), size: 22),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Official PCSO Draw Schedule: ${_selectedType!.name}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '📅 Draw Days: ${schedule?.drawDaysText ?? 'Regular Schedule'} at 9:00 PM PHT',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  if (nextDraw != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '⏰ Next Upcoming Draw: ${DateFormat('EEEE, MMMM d, yyyy').format(nextDraw)} (9:00 PM)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF60A5FA) : Colors.blue.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    'Number Range: ${_selectedType!.rangeDescription}  |  Required Numbers: Exactly ${_selectedType!.numberCount} Unique Numbers',
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : Colors.blueGrey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 2. Official PCSO Prize Breakdown Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 20),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Official PCSO Prize Categories (Online Rule):',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    children: prizes.map((tier) {
                                      final isJackpot = tier.isJackpot;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isJackpot
                                              ? (isDark ? const Color(0xFF3A2800) : Colors.amber.shade50)
                                              : (isDark ? const Color(0xFF0F172A) : Colors.white),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isJackpot
                                                ? Colors.amber.shade500
                                                : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                                            width: isJackpot ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: isJackpot ? Colors.amber.shade700 : const Color(0xFF1E3A8A),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${tier.matchCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tier.tierName,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: isJackpot
                                                          ? (isDark ? const Color(0xFFFCD34D) : Colors.amber.shade900)
                                                          : (isDark ? Colors.white : Colors.black87),
                                                    ),
                                                  ),
                                                  Text(
                                                    isJackpot && latestDraw != null
                                                        ? 'Recent Draw Jackpot: ${latestDraw.formattedJackpot}'
                                                        : tier.prizeDescription,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isJackpot
                                                          ? (isDark ? const Color(0xFFFDE68A) : Colors.amber.shade800)
                                                          : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
                                                      fontWeight: isJackpot ? FontWeight.w600 : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  // Conditional Mode Rendering: Auto Generator vs Manual Playslip
                  if (_mode == LuckyPickMode.autoGenerator)
                    _buildAutoGenerator()
                  else
                    _buildManualPlayslip(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoGenerator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.pcsoGoldGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pcsoGold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.casino, size: 26, color: Color(0xFF0F172A)),
              label: const Text(
                'GENERATE LUCKY PICK',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              onPressed: _generateNumbers,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_generatedNumbers.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Your Generated Combination (Sorted Ascending):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _generatedNumbers.map((n) => LottoBall(number: n, size: 48)).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Speak Numbers'),
                  onPressed: () {
                    final speech = 'Your lucky numbers are ${TextToSpeechService.formatSpokenNumbers(_generatedNumbers)}.';
                    TextToSpeechService.instance.speak(speech);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.volume_off),
                  label: const Text('Stop Voice'),
                  onPressed: () => TextToSpeechService.instance.stop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _buildDrawDateSelector(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.pcsoHeroGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pcsoBlue.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save, color: Color(0xFFFFB300)),
              label: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE LUCKY PICK COMBINATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: _isSaving ? null : () => _saveCurrentPick(_generatedNumbers, 'Lucky Pick Generator'),
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 16),
          _buildMessageBanner(),
        ],
      ],
    );
  }

  Widget _buildManualPlayslip() {
    if (_selectedType == null) return const SizedBox.shrink();
    final maxNum = _selectedType!.maxNumber;
    final sortedSelected = _manualSelectedNumbers.toList()..sort();
    final isComplete = _manualSelectedNumbers.length == 6;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFF1E3A8A).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Playslip Top Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: AppTheme.pcsoHeroGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.pcsoGoldGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_document, color: Color(0xFF0F172A), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OFFICIAL PCSO PLAYSLIP',
                          style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 1.5,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedType!.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isComplete ? const Color(0xFF10B981) : AppTheme.pcsoGold,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isComplete ? Icons.check_circle : Icons.edit,
                        color: isComplete ? Colors.white : const Color(0xFF0F172A),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isComplete
                            ? '6 / 6 Shaded'
                            : 'Shaded: ${_manualSelectedNumbers.length} / 6 (${6 - _manualSelectedNumbers.length} left)',
                        style: TextStyle(
                          color: isComplete ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions & Live Tray Header
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Shade 6 Numbers by tapping the lotto balls below:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.auto_fix_high, size: 16),
                          label: const Text('Quick Fill Remaining', style: TextStyle(fontSize: 12)),
                          onPressed: _manualSelectedNumbers.length < 6 ? _quickFillRemaining : null,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.cleaning_services, size: 16, color: Colors.red),
                          label: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.red)),
                          onPressed: _manualSelectedNumbers.isNotEmpty ? _clearManualSelection : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Live Shaded Combination Tray
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                  ),
                  child: sortedSelected.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No numbers shaded yet. Tap any 6 circular lotto balls below.',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...sortedSelected.map((n) {
                              return Tooltip(
                                message: 'Tap to unshade #$n',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () => _toggleManualNumber(n),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      LottoBall(number: n, size: 46),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 10, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (sortedSelected.length < 6)
                              ...List.generate(6 - sortedSelected.length, (idx) {
                                return Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF475569) : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${sortedSelected.length + idx + 1}',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                ),
                const SizedBox(height: 16),

                // TTS Voice Bar for Manual Combination
                if (isComplete) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up, size: 16),
                        label: const Text('Speak Numbers', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          final speech = 'Your selected numbers are ${TextToSpeechService.formatSpokenNumbers(sortedSelected)}.';
                          TextToSpeechService.instance.speak(speech);
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.volume_off, size: 16),
                        label: const Text('Stop Voice', style: TextStyle(fontSize: 12)),
                        onPressed: () => TextToSpeechService.instance.stop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // The Circular Lotto Ball Shading Board (Responsive & Spaced)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int cols = 10;
                    double spacing = 14;

                    if (width < 460) {
                      cols = 6;
                      spacing = 8;
                    } else if (width < 720) {
                      cols = 8;
                      spacing = 10;
                    } else {
                      cols = 10;
                      spacing = 14;
                    }

                    final cellWidth = (width - ((cols - 1) * spacing)) / cols;
                    final ballSize = (cellWidth * 0.84).clamp(38.0, 52.0);

                    return Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: width > 700 ? 18 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                        ),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: maxNum,
                        itemBuilder: (context, idx) {
                          final number = idx + 1;
                          final isShaded = _manualSelectedNumbers.contains(number);
                          return _buildCircularShadingBall(number, isShaded, isDark, ballSize);
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // Draw Date Association
                _buildDrawDateSelector(),
                const SizedBox(height: 18),

                // Save Manual Pick Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: isComplete ? AppTheme.pcsoHeroGradient : null,
                    color: isComplete ? null : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isComplete
                        ? [
                            BoxShadow(
                              color: AppTheme.pcsoBlue.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: isComplete ? Colors.white : (isDark ? Colors.white38 : Colors.grey.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(Icons.save, color: isComplete ? const Color(0xFFFFB300) : null),
                    label: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            isComplete
                                ? 'SAVE MANUAL LUCKY PICK (6/6)'
                                : 'SHADE 6 NUMBERS TO SAVE (${_manualSelectedNumbers.length}/6)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                    onPressed: (isComplete && !_isSaving)
                        ? () => _saveCurrentPick(sortedSelected, 'Manual Shaded Pick')
                        : null,
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  _buildMessageBanner(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBallColor(int n) {
    if (n <= 10) return const Color(0xFFFBBF24); // Gold / Yellow
    if (n <= 20) return const Color(0xFF60A5FA); // Blue
    if (n <= 30) return const Color(0xFFF87171); // Red
    if (n <= 40) return const Color(0xFF34D399); // Green
    if (n <= 50) return const Color(0xFFA78BFA); // Purple
    return const Color(0xFFF472B6);              // Pink (51-58)
  }

  Color _darkenColor(Color color, [double factor = 0.20]) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness - factor).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  Widget _buildCircularShadingBall(int number, bool isShaded, bool isDark, double ballSize) {
    final ballColor = _getBallColor(number);
    final formattedNumber = number.toString().padLeft(2, '0');

    return Center(
      child: Tooltip(
        message: isShaded ? 'Tap to unshade #$formattedNumber' : 'Tap to shade #$formattedNumber',
        child: InkWell(
          onTap: () => _toggleManualNumber(number),
          customBorder: const CircleBorder(),
          hoverColor: ballColor.withValues(alpha: 0.15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: ballSize,
            height: ballSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isShaded
                  ? RadialGradient(
                      center: const Alignment(-0.35, -0.35),
                      radius: 0.85,
                      colors: [
                        Colors.white,
                        ballColor,
                        _darkenColor(ballColor, 0.3),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    )
                  : RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      radius: 0.85,
                      colors: isDark
                          ? [
                              const Color(0xFF475569),
                              const Color(0xFF334155),
                              const Color(0xFF1E293B),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFF8FAFC),
                              const Color(0xFFE2E8F0),
                            ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
              border: Border.all(
                color: isShaded
                    ? Colors.white
                    : (isDark ? ballColor.withValues(alpha: 0.6) : ballColor.withValues(alpha: 0.45)),
                width: isShaded ? 2.2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isShaded
                      ? ballColor.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: isShaded ? 10 : 4,
                  spreadRadius: isShaded ? 2 : 0,
                  offset: isShaded ? const Offset(0, 3) : const Offset(1, 2),
                ),
                if (isShaded)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(2, 3),
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Text(
                  formattedNumber,
                  style: TextStyle(
                    fontSize: ballSize * 0.40,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: isShaded
                        ? Colors.black87
                        : (isDark ? Colors.white : Colors.blueGrey.shade800),
                    shadows: isShaded
                        ? const [
                            Shadow(
                              color: Colors.white70,
                              blurRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (isShaded)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawDateSelector() {
    final sched = _selectedType != null ? PcsoGameRuleService.getSchedule(_selectedType!.code) : null;
    final isValidDay = sched == null || sched.isDrawDay(_selectedDrawDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Associate Draw Date: ', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.calendar_month, size: 18),
              label: Text(DateFormat('MMMM d, yyyy (EEEE)').format(_selectedDrawDate)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDrawDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDrawDate = picked);
                }
              },
            ),
            const SizedBox(width: 8),
            if (sched != null)
              TextButton.icon(
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Set Next Draw Date', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() {
                    _selectedDrawDate = sched.getNextDrawDate();
                  });
                },
              ),
          ],
        ),
        if (!isValidDay) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.deepOrange),
              const SizedBox(width: 6),
              Text(
                'Note: ${DateFormat('EEEE').format(_selectedDrawDate)} is not an official draw day for ${_selectedType!.name} (${sched.drawDaysText}).',
                style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMessageBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(_message!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
