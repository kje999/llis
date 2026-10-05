import 'package:flutter/material.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/core/services/text_to_speech_service.dart';
import 'package:my_lucky_lotto_pred/features/predictions/domain/prediction_engine.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/save_pick_dialog.dart';
import 'lotto_ball.dart';

class StatisticalSuggestionCard extends StatelessWidget {
  final StatisticalSuggestion suggestion;
  final String lottoTypeName;
  final LottoType? lottoType;

  const StatisticalSuggestionCard({
    super.key,
    required this.suggestion,
    required this.lottoTypeName,
    this.lottoType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action & header row with Wrap to prevent overflow on mobile
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.pcsoGoldGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '★ SUGGESTION #${suggestion.rank}',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      lottoTypeName,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.blue.shade200),
                      ),
                      child: Text(
                        suggestion.strategyProfile,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lottoType != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.pcsoBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.bookmark_add, size: 15, color: Color(0xFFFFB300)),
                        label: const Text('Use as Pick', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          showSavePickConfirmationDialog(
                            context: context,
                            numbers: suggestion.numbers,
                            lottoType: lottoType!,
                            sourceTitle: 'Statistical Suggestion #${suggestion.rank}',
                          );
                        },
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Read suggested combination',
                      icon: Icon(Icons.volume_up, color: isDark ? Colors.white70 : Colors.blueGrey),
                      onPressed: () {
                        final speech = 'Statistical suggestion number ${suggestion.rank} is: '
                            '${TextToSpeechService.formatSpokenNumbers(suggestion.numbers)}. '
                            'Statistical ranking score is ${suggestion.statisticalScore}.';
                        TextToSpeechService.instance.speak(speech);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: suggestion.numbers.map((n) => LottoBall(number: n, size: 40)).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                const Text(
                  'Statistical Ranking Score: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${suggestion.statisticalScore} pts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF60A5FA) : AppTheme.pcsoBlue,
                  ),
                ),
                Text(
                  '(Internal historical weight - not a win guarantee)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistical Justification / Why this combination?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...suggestion.explanationPoints.map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.grey.shade800,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
