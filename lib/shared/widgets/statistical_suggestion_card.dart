import 'package:flutter/material.dart';
import 'package:my_lucky_lotto_pred/core/services/text_to_speech_service.dart';
import 'package:my_lucky_lotto_pred/features/predictions/domain/prediction_engine.dart';
import 'lotto_ball.dart';

class StatisticalSuggestionCard extends StatelessWidget {
  final StatisticalSuggestion suggestion;
  final String lottoTypeName;

  const StatisticalSuggestionCard({
    super.key,
    required this.suggestion,
    required this.lottoTypeName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '★ STATISTICAL SUGGESTION #${suggestion.rank}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lottoTypeName,
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Read suggested combination',
                  icon: const Icon(Icons.volume_up, color: Colors.blueGrey),
                  onPressed: () {
                    final speech = 'Statistical suggestion number ${suggestion.rank} is: '
                        '${TextToSpeechService.formatSpokenNumbers(suggestion.numbers)}. '
                        'Statistical ranking score is ${suggestion.statisticalScore}.';
                    TextToSpeechService.instance.speak(speech);
                  },
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
            Row(
              children: [
                const Text(
                  'Statistical Ranking Score: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${suggestion.statisticalScore} pts',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Internal historical weight - not a win guarantee)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistical Justification / Why this combination?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  ...suggestion.explanationPoints.map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
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


