import 'package:flutter/material.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/core/services/text_to_speech_service.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'lotto_ball.dart';

class LottoResultCard extends StatelessWidget {
  final LottoResult result;

  const LottoResultCard({super.key, required this.result});

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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : Colors.blue.shade200,
                        ),
                      ),
                      child: Text(
                        result.lottoTypeName ?? 'PCSO 6-Number Lotto',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF93C5FD) : AppTheme.pcsoBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'OFFICIAL DRAW',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Read numbers aloud',
                  icon: Icon(Icons.volume_up, color: isDark ? Colors.white70 : Colors.blueGrey),
                  onPressed: () {
                    final speech = 'The latest ${result.lottoTypeName ?? 'Lotto'} result for ${result.drawDate} is: '
                        '${TextToSpeechService.formatSpokenNumbers(result.numbers)}. '
                        'Jackpot prize is ${result.formattedJackpot}.';
                    TextToSpeechService.instance.speak(speech);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Draw Date: ${result.drawDate}',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: result.numbers.map((n) => LottoBall(number: n)).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Jackpot: ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppTheme.pcsoGoldGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            result.formattedJackpot,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          result.winners > 0 ? Icons.emoji_events : Icons.person_outline,
                          size: 14,
                          color: result.winners > 0 ? const Color(0xFFF59E0B) : Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Jackpot Winners: ${result.winners}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: result.winners > 0 ? const Color(0xFFF59E0B) : Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  'Source: ${result.source}',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
