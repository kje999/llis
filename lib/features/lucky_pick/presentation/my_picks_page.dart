import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/domain/auth_service.dart';
import '../../core/services/text_to_speech_service.dart';
import '../../shared/models/lucky_pick.dart';
import '../domain/lucky_pick_repository.dart';
import '../../shared/widgets/lotto_ball.dart';

class MyPicksPage extends StatefulWidget {
  const MyPicksPage({super.key});

  @override
  State<MyPicksPage> createState() => _MyPicksPageState();
}

class _MyPicksPageState extends State<MyPicksPage> {
  List<LuckyPick> _picks = [];
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
    final list = await repo.getByUserId(auth.currentUser!.id);
    if (mounted) {
      setState(() {
        _picks = list;
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
                    'Track and verify your generated combinations against official PCSO draw results.',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Picks',
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pick.lottoTypeName ?? 'PCSO 6-Number Lotto',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(pick),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up, size: 20, color: Colors.blueGrey),
                              onPressed: () {
                                final speech = 'Your pick for ${pick.lottoTypeName ?? 'Lotto'} is: '
                                    '${TextToSpeechService.formatSpokenNumbers(pick.numbers)}.';
                                TextToSpeechService.instance.speak(speech);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target Draw Date: ${pick.drawDate}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: pick.numbers.map((n) => LottoBall(number: n, size: 38)).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade200),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              pick.isChecked
                                  ? 'Result Checked: Matched ${pick.matchCount} / 6 numbers'
                                  : 'Awaiting Official PCSO Draw',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pick.isChecked ? Colors.black87 : Colors.orange.shade800,
                              ),
                            ),
                            Text(
                              'Generated: ${pick.generatedAt.toLocal().toString().substring(0, 16)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LuckyPick pick) {
    Color bg;
    Color fg;
    String label;

    switch (pick.status) {
      case 'WINNER':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = '★ JACKPOT WINNER (6/6)';
        break;
      case 'PARTIAL_MATCH':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        label = 'MATCH (${pick.matchCount}/6)';
        break;
      case 'NOT_WINNING':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = 'NO WIN (${pick.matchCount}/6)';
        break;
      default:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = 'PENDING DRAW';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
