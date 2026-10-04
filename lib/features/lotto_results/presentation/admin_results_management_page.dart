import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_type.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_service.dart';

class AdminResultsManagementPage extends StatefulWidget {
  const AdminResultsManagementPage({super.key});

  @override
  State<AdminResultsManagementPage> createState() => _AdminResultsManagementPageState();
}

class _AdminResultsManagementPageState extends State<AdminResultsManagementPage> {
  final LuckyPickService _pickService = LuckyPickService();
  List<LottoType> _types = [];
  List<LottoResult> _results = [];
  bool _isLoading = true;

  // Pagination Configuration: 20 per page, latest first
  static const int _pageSize = 20;
  int _currentPage = 1;
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final typeRepo = context.read<LottoTypeRepository>();
    final resultRepo = context.read<LottoResultRepository>();

    final types = await typeRepo.getAll();
    final total = await resultRepo.getTotalCount();
    final offset = (_currentPage - 1) * _pageSize;

    // Ordered by draw_date DESC (recent/latest top)
    final results = await resultRepo.getAll(limit: _pageSize, offset: offset);

    if (mounted) {
      setState(() {
        _types = types;
        _totalRecords = total;
        _results = results;
        _isLoading = false;
      });
    }
  }

  int get _totalPages {
    if (_totalRecords == 0) return 1;
    return (_totalRecords / _pageSize).ceil();
  }

  void _onPageChanged(int newPage) {
    if (newPage < 1 || newPage > _totalPages) return;
    setState(() {
      _currentPage = newPage;
      _isLoading = true;
    });
    _loadData();
  }

  void _showAddResultDialog() {
    if (_types.isEmpty) return;
    LottoType selectedType = _types.first;
    DateTime drawDate = DateTime.now();
    final numControllers = List.generate(6, (_) => TextEditingController());
    final jackpotController = TextEditingController(text: '15000000');
    final winnersController = TextEditingController(text: '0');
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Official Lotto Draw Result'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.red.shade50,
                      child: Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const Text('Select Game:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  DropdownButton<LottoType>(
                    isExpanded: true,
                    value: selectedType,
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Draw Date: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton(
                        child: Text(DateFormat('yyyy-MM-dd').format(drawDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: drawDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => drawDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Enter Exactly 6 Numbers (${selectedType.rangeDescription}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(6, (i) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: TextField(
                            controller: numControllers[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: jackpotController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jackpot Prize (PHP)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: winnersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Number of Winners', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                onPressed: () async {
                  final nums = <int>[];
                  for (final c in numControllers) {
                    final n = int.tryParse(c.text.trim());
                    if (n != null) nums.add(n);
                  }

                  // Validate against rules
                  if (nums.length != 6) {
                    setDialogState(() => dialogError = 'Please enter all 6 numbers.');
                    return;
                  }

                  if (!_pickService.validateCombination(selectedType, nums)) {
                    setDialogState(() => dialogError = 'Invalid numbers! Must be unique and in range 1..${selectedType.maxNumber}.');
                    return;
                  }

                  final jackpot = double.tryParse(jackpotController.text.trim()) ?? 0.0;
                  final winners = int.tryParse(winnersController.text.trim()) ?? 0;
                  final dateStr = DateFormat('yyyy-MM-dd').format(drawDate);

                  final newResult = LottoResult(
                    id: 0,
                    lottoTypeId: selectedType.id,
                    drawDate: dateStr,
                    number1: nums[0],
                    number2: nums[1],
                    number3: nums[2],
                    number4: nums[3],
                    number5: nums[4],
                    number6: nums[5],
                    jackpotPrize: jackpot,
                    winners: winners,
                    source: 'ADMIN_MANUAL',
                    scrapedAt: DateTime.now(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  final repo = context.read<LottoResultRepository>();
                  await repo.insert(newResult);
                  Navigator.pop(ctx);
                  _loadData();
                },
                child: const Text('Save Result'),
              ),
            ],
          );
        },
      ),
    );
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
                    'Official PCSO Draw Results Directory',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 4),
                  Text('View, manually insert, edit, or delete official draw results.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                icon: const Icon(Icons.add),
                label: const Text('Add Manual Draw Result'),
                onPressed: _showAddResultDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Results Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${((_currentPage - 1) * _pageSize) + 1}–${(((_currentPage - 1) * _pageSize) + _results.length).clamp(0, _totalRecords)} of $_totalRecords draw results (Latest first)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E3A8A)),
                ),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final r = _results[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.lottoTypeName ?? 'PCSO Lotto', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Draw: ${r.drawDate} | Jackpot: ${r.formattedJackpot} | Winners: ${r.winners}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        Wrap(
                          spacing: 4,
                          children: r.numbers.map((n) => LottoBall(number: n, size: 30)).toList(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete Draw',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: const Text('Are you sure you want to delete this draw result?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await context.read<LottoResultRepository>().delete(r.id);
                              _loadData();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Pagination Controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Previous 20'),
                    onPressed: _currentPage > 1 ? () => _onPageChanged(_currentPage - 1) : null,
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages (20 items/page)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Next 20'),
                    onPressed: _currentPage < _totalPages ? () => _onPageChanged(_currentPage + 1) : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
