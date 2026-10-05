import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/pcso_game_rule_service.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/shared/models/lucky_pick.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';

/// Displays a confirmation dialog before saving a combination to the database.
Future<bool?> showSavePickConfirmationDialog({
  required BuildContext context,
  required List<int> numbers,
  required LottoType lottoType,
  String sourceTitle = 'Combination',
  VoidCallback? onSaved,
}) async {
  final sortedNumbers = List<int>.from(numbers)..sort();
  final sched = PcsoGameRuleService.getSchedule(lottoType.code);
  DateTime selectedDate = sched?.getNextDrawDate() ?? DateTime.now();

  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final isValidDay = sched == null || sched.isDrawDay(selectedDate);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.bookmark_add, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'Confirm Lucky Pick',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to use this $sourceTitle as your Lucky Pick for ${lottoType.name} and save it to your database?',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: sortedNumbers.map((n) => LottoBall(number: n, size: 40)).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Associate Draw Date:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.calendar_month, size: 16),
                        label: Text(DateFormat('MMMM d, yyyy (EEEE)').format(selectedDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      if (sched != null)
                        TextButton(
                          child: const Text('Next Draw', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setDialogState(() {
                              selectedDate = sched.getNextDrawDate();
                            });
                          },
                        ),
                    ],
                  ),
                  if (!isValidDay) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Note: ${DateFormat('EEEE').format(selectedDate)} is not an official draw day for ${lottoType.name} (${sched.drawDaysText}).',
                      style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Confirm & Save to Database', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final auth = context.read<AuthService>();
                  if (auth.currentUser == null) {
                    Navigator.of(dialogCtx).pop(false);
                    return;
                  }

                  final user = auth.currentUser!;
                  final pickRepo = context.read<LuckyPickRepository>();
                  final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

                  final newPick = LuckyPick(
                    id: 0,
                    userId: user.id,
                    lottoTypeId: lottoType.id,
                    drawDate: dateStr,
                    number1: sortedNumbers[0],
                    number2: sortedNumbers[1],
                    number3: sortedNumbers[2],
                    number4: sortedNumbers[3],
                    number5: sortedNumbers[4],
                    number6: sortedNumbers[5],
                    generatedAt: DateTime.now(),
                    isChecked: false,
                    matchCount: 0,
                    status: 'PENDING',
                  );

                  await pickRepo.insert(newPick, username: user.username);
                  Navigator.of(dialogCtx).pop(true);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved combination ${sortedNumbers.map((e) => e.toString().padLeft(2, '0')).join("-")} for ${lottoType.name} to My Lucky Picks!'),
                        backgroundColor: const Color(0xFF1E3A8A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    onSaved?.call();
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
