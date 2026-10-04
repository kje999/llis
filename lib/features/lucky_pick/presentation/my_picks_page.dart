import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/core/services/text_to_speech_service.dart';
import 'package:my_lucky_lotto_pred/shared/models/lucky_pick.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/pcso_game_rule_service.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_service.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';

class MyPicksPage extends StatefulWidget {
  const MyPicksPage({super.key});

  @override
  State<MyPicksPage> createState() => _MyPicksPageState();
}

class _MyPicksPageState extends State<MyPicksPage> {
  final LuckyPickService _pickService = LuckyPickService();
  List<LuckyPick> _picks = [];
  Map<String, LottoResult?> _officialResultsCache = {}; // Key: "lottoTypeId_drawDate"
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPicks();
  }

  Future<void> _loadPicks() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;
    final repo = context.read<LuckyPickRepository>();
    final resultRepo = context.read<LottoResultRepository>();

    final list = await repo.getByUserId(auth.currentUser!.id);

    // Fetch matching official results for each unique (lottoTypeId, drawDate)
    final cache = <String, LottoResult?>{};
    for (final pick in list) {
      final key = '${pick.lottoTypeId}_${pick.drawDate}';
      if (!cache.containsKey(key)) {
        final draw = await resultRepo.findExisting(pick.lottoTypeId, pick.drawDate);
        cache[key] = draw;
      }
    }

    if (mounted) {
      setState(() {
        _picks = list;
        _officialResultsCache = cache;
        _isLoading = false;
      });
    }
  }

  Future<void> _recheckPick(LuckyPick pick, LottoResult officialDraw) async {
    final matches = _pickService.countMatches(pick.numbers, officialDraw.numbers);
    final status = _pickService.determineStatus(matches);

    final updated = pick.copyWith(
      isChecked: true,
      matchCount: matches,
      status: status,
    );

    final repo = context.read<LuckyPickRepository>();
    await repo.update(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Re-verified against draw ${pick.drawDate}: $matches matches!'),
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      );
      _loadPicks();
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
                    'My Saved Lucky Picks',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Verify numbers against official PCSO draw results and view exact winning prize tiers.',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh & Check'),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadPicks();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_picks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No saved picks yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('Generate numbers from the Lucky Pick tab to save your combinations.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _picks.length,
              itemBuilder: (context, index) {
                final pick = _picks[index];
                final cacheKey = '${pick.lottoTypeId}_${pick.drawDate}';
                final officialDraw = _officialResultsCache[cacheKey];

                return _buildPickCard(pick, officialDraw);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPickCard(LuckyPick pick, LottoResult? officialDraw) {
    final gameCode = pick.lottoTypeCode ?? 'LOTTO_6_42';
    final schedule = PcsoGameRuleService.getSchedule(gameCode);

    // Calculate official PCSO prize if draw result exists
    PcsoPrizeResult? prizeResult;
    if (officialDraw != null) {
      prizeResult = PcsoGameRuleService.calculatePrize(
        gameCode: gameCode,
        userNumbers: pick.numbers,
        officialNumbers: officialDraw.numbers,
        jackpotPrize: officialDraw.jackpotPrize,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Game Title & Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        pick.lottoTypeName ?? 'PCSO 6-Number Lotto',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(pick, prizeResult),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Read numbers aloud',
                      icon: const Icon(Icons.volume_up, size: 22, color: Colors.blueGrey),
                      onPressed: () {
                        final speech = 'Your pick for ${pick.lottoTypeName ?? 'Lotto'} is: '
                            '${TextToSpeechService.formatSpokenNumbers(pick.numbers)}. '
                            'Target draw date is ${pick.drawDate}.';
                        TextToSpeechService.instance.speak(speech);
                      },
                    ),
                    if (officialDraw != null && (!pick.isChecked || pick.matchCount != (prizeResult?.matchCount ?? 0)))
                      IconButton(
                        tooltip: 'Check against official draw',
                        icon: const Icon(Icons.sync, size: 22, color: Color(0xFF1E3A8A)),
                        onPressed: () => _recheckPick(pick, officialDraw),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Target Draw Date & Schedule Notice
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  'Associated Draw Date: ${pick.drawDate}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                ),
                if (schedule != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${schedule.drawDaysText} at 9:00 PM)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Picked Combination Balls
            const Text(
              'Your Picked Combination:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueGrey),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pick.numbers.map((n) {
                  final isMatched = officialDraw != null && officialDraw.numbers.contains(n);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        LottoBall(number: n, size: 40),
                        if (isMatched)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            // Official Draw Comparison Box
            if (officialDraw != null && prizeResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: prizeResult.isWinning
                      ? (prizeResult.matchCount == 6 ? Colors.amber.shade50 : Colors.green.shade50)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: prizeResult.isWinning
                        ? (prizeResult.matchCount == 6 ? Colors.amber.shade400 : Colors.green.shade300)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          prizeResult.isWinning ? Icons.celebration : Icons.info_outline,
                          size: 20,
                          color: prizeResult.isWinning
                              ? (prizeResult.matchCount == 6 ? Colors.amber.shade900 : Colors.green.shade800)
                              : Colors.blueGrey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Official Draw Result for ${pick.drawDate}: ${officialDraw.formattedNumbers}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prizeResult.prizeDescription,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: prizeResult.isWinning
                            ? (prizeResult.matchCount == 6 ? Colors.amber.shade900 : Colors.green.shade900)
                            : Colors.black87,
                      ),
                    ),
                    if (prizeResult.matchedNumbers.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Matched Numbers: ${prizeResult.matchedNumbers.map((m) => m.toString().padLeft(2, '0')).join(', ')} (${prizeResult.matchCount} of 6 matches)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: prizeResult.isWinning ? Colors.green.shade800 : Colors.blueGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Awaiting official PCSO draw for ${pick.drawDate}. Result checking will occur automatically once PCSO draws at 9:00 PM.',
                        style: TextStyle(fontSize: 12, color: Colors.brown.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade200),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  officialDraw != null
                      ? 'Status: Verified with Official PCSO Draw'
                      : 'Status: Pending Draw Result',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: officialDraw != null ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                Text(
                  'Created: ${pick.generatedAt.toLocal().toString().substring(0, 16)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LuckyPick pick, PcsoPrizeResult? prizeResult) {
    if (prizeResult != null) {
      if (prizeResult.matchCount == 6) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(6)),
          child: const Text('🎉 JACKPOT WINNER (6/6)', style: TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold)),
        );
      } else if (prizeResult.isWinning) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
          child: Text('WINNER: ${prizeResult.tierName}', style: TextStyle(color: Colors.green.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
        );
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
          child: Text('NO WIN (${prizeResult.matchCount}/6)', style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
      child: const Text('PENDING DRAW', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
