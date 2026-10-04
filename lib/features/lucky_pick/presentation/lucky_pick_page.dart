import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/core/services/text_to_speech_service.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/shared/models/lucky_pick.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_service.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_disclaimer_banner.dart';

class LuckyPickPage extends StatefulWidget {
  const LuckyPickPage({super.key});

  @override
  State<LuckyPickPage> createState() => _LuckyPickPageState();
}

class _LuckyPickPageState extends State<LuckyPickPage> {
  final LuckyPickService _pickService = LuckyPickService();
  List<LottoType> _lottoTypes = [];
  LottoType? _selectedType;
  List<int> _generatedNumbers = [];
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
        }
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

    // Speak generated numbers via TTS
    final speech = 'Your lucky numbers are ${TextToSpeechService.formatSpokenNumbers(numbers)}.';
    TextToSpeechService.instance.speak(speech);
  }

  Future<void> _savePick() async {
    if (_selectedType == null || _generatedNumbers.isEmpty) return;
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;

    setState(() => _isSaving = true);
    final pickRepo = context.read<LuckyPickRepository>();
    final newPick = LuckyPick(
      id: 0,
      userId: auth.currentUser!.id,
      lottoTypeId: _selectedType!.id,
      drawDate: DateFormat('yyyy-MM-dd').format(_selectedDrawDate),
      number1: _generatedNumbers[0],
      number2: _generatedNumbers[1],
      number3: _generatedNumbers[2],
      number4: _generatedNumbers[3],
      number5: _generatedNumbers[4],
      number6: _generatedNumbers[5],
      generatedAt: DateTime.now(),
      isChecked: false,
      matchCount: 0,
      status: 'PENDING',
    );

    await pickRepo.insert(newPick);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _message = 'Lucky Pick saved successfully for ${DateFormat('MMMM d, yyyy').format(_selectedDrawDate)}!';
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
            'Lucky Pick Generator',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Generate random, cryptographically secure 6-number combinations for the 5 PCSO games.',
            style: TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
          const SizedBox(height: 12),
          const LottoDisclaimerBanner(),
          const SizedBox(height: 16),
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
                              _generatedNumbers = [];
                              _message = null;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Color(0xFF1E3A8A), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Number Range: ${_selectedType!.rangeDescription}  |  Required Numbers: Exactly ${_selectedType!.numberCount} Unique Numbers',
                            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.casino, size: 28),
                      label: const Text('GENERATE LUCKY PICK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: _generateNumbers,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Speak Numbers'),
                          onPressed: () {
                            final speech = 'Your lucky numbers are ${TextToSpeechService.formatSpokenNumbers(_generatedNumbers)}.';
                            TextToSpeechService.instance.speak(speech);
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.volume_off),
                          label: const Text('Stop Voice'),
                          onPressed: () => TextToSpeechService.instance.stop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Associate Draw Date: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        ActionChip(
                          avatar: const Icon(Icons.calendar_month, size: 18),
                          label: Text(DateFormat('MMMM d, yyyy').format(_selectedDrawDate)),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.save),
                        label: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SAVE LUCKY PICK COMBINATION', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isSaving ? null : _savePick,
                      ),
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Container(
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
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
