import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../lotto_results/domain/lotto_type_repository.dart';
import '../../lotto_results/domain/lotto_result_repository.dart';
import '../../shared/models/lotto_type.dart';
import '../../shared/models/lotto_result.dart';
import '../../shared/widgets/lotto_result_card.dart';

class LottoResultsPage extends StatefulWidget {
  const LottoResultsPage({super.key});

  @override
  State<LottoResultsPage> createState() => _LottoResultsPageState();
}

class _LottoResultsPageState extends State<LottoResultsPage> {
  List<LottoType> _types = [];
  int? _selectedTypeId;
  List<LottoResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final typeRepo = context.read<LottoTypeRepository>();
    final resultRepo = context.read<LottoResultRepository>();

    final types = await typeRepo.getAll();
    final results = await resultRepo.getAll(limit: 60, lottoTypeId: _selectedTypeId);

    if (mounted) {
      setState(() {
        _types = types;
        _results = results;
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
                    'Official PCSO Draw Results',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Synchronized authoritative draw results for Philippine 6-number lotto games.',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadData();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All 5 Lotto Games'),
                  selected: _selectedTypeId == null,
                  onSelected: (val) {
                    setState(() {
                      _selectedTypeId = null;
                      _isLoading = true;
                    });
                    _loadData();
                  },
                ),
                const SizedBox(width: 8),
                ..._types.map((type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.name),
                        selected: _selectedTypeId == type.id,
                        onSelected: (val) {
                          setState(() {
                            _selectedTypeId = val ? type.id : null;
                            _isLoading = true;
                          });
                          _loadData();
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No draw results found for selected filter.', style: TextStyle(color: Colors.grey.shade600)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                return LottoResultCard(result: _results[index]);
              },
            ),
        ],
      ),
    );
  }
}
