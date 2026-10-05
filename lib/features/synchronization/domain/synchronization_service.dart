import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_lucky_lotto_pred/core/constants/api_constants.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_type_repository.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_service.dart';
import 'package:my_lucky_lotto_pred/features/notifications/domain/notification_repository.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/shared/models/synchronization_log.dart';
import 'package:my_lucky_lotto_pred/shared/models/in_app_notification.dart';
import 'pcso_parser.dart';

class SyncSummary {
  final int recordsFound;
  final int recordsInserted;
  final int recordsUpdated;
  final int recordsSkipped;
  final String status;
  final String? errorMessage;

  SyncSummary({
    required this.recordsFound,
    required this.recordsInserted,
    required this.recordsUpdated,
    required this.recordsSkipped,
    required this.status,
    this.errorMessage,
  });
}

class SynchronizationService {
  final LottoTypeRepository _typeRepo;
  final LottoResultRepository _resultRepo;
  final LuckyPickRepository _pickRepo;
  final LuckyPickService _pickService;
  final SynchronizationRepository _syncRepo;
  final NotificationRepository _notifRepo;

  SynchronizationService({
    required LottoTypeRepository typeRepo,
    required LottoResultRepository resultRepo,
    required LuckyPickRepository pickRepo,
    required LuckyPickService pickService,
    required SynchronizationRepository syncRepo,
    required NotificationRepository notifRepo,
  }) : _typeRepo = typeRepo,
       _resultRepo = resultRepo,
       _pickRepo = pickRepo,
       _pickService = pickService,
       _syncRepo = syncRepo,
       _notifRepo = notifRepo;

  /// Runs PCSO synchronization:
  /// Connects to backend sync service, parses direct HTML if provided, or generates live draws for date range
  Future<SyncSummary> synchronize({
    String? syncEndpoint,
    DateTime? fromDate,
    DateTime? toDate,
    String? selectedGameCode,
    String? rawHtmlContent,
  }) async {
    final activeEndpoint = syncEndpoint ?? ApiConstants.syncEndpoint;
    final startTime = DateTime.now();
    int found = 0;
    int inserted = 0;
    int updated = 0;
    int skipped = 0;
    String? error;

    final targetEnd = toDate ?? DateTime.now();
    final targetStart =
        fromDate ?? targetEnd.subtract(const Duration(days: 365));

    try {
      List<Map<String, dynamic>> rawDraws = [];

      // 1. If Admin pasted raw HTML or table text directly from pcso.gov.ph
      if (rawHtmlContent != null && rawHtmlContent.trim().isNotEmpty) {
        rawDraws = _parseRawHtmlOrText(rawHtmlContent);
      }

      // 2. If no direct HTML was provided, trigger live scraping via backend sync service
      if (rawDraws.isEmpty) {
        try {
          final triggerUri = Uri.parse(ApiConstants.triggerSyncEndpoint);
          final triggerRes = await http
              .post(
                triggerUri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'fromDate': DateFormat('yyyy-MM-dd').format(targetStart),
                  'toDate': DateFormat('yyyy-MM-dd').format(targetEnd),
                  'gameFilter': selectedGameCode ?? 'ALL',
                }),
              )
              .timeout(const Duration(seconds: 30));
          if (triggerRes.statusCode == 200) {
            final summaryData = jsonDecode(triggerRes.body);
            if (summaryData['draws'] is List && (summaryData['draws'] as List).isNotEmpty) {
              rawDraws = List<Map<String, dynamic>>.from(summaryData['draws']);
            }
          }
        } catch (_) {
          // Continue to query cache if trigger timed out or was already running
        }

        try {
          final uri = Uri.parse(activeEndpoint).replace(
            queryParameters: {
              'startDate': DateFormat('yyyy-MM-dd').format(targetStart),
              'endDate': DateFormat('yyyy-MM-dd').format(targetEnd),
              'limit': '1000',
              if (selectedGameCode != null && selectedGameCode != 'ALL')
                'game': selectedGameCode,
            },
          );

          final response = await http
              .get(uri)
              .timeout(const Duration(seconds: 6));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is List) {
              rawDraws = List<Map<String, dynamic>>.from(data);
            }
          }
        } catch (_) {
          // No fake fallback on network or API failure
        }
      }

      // No fake fallback: If still empty, do not fabricate synthetic draws
      if (rawDraws.isEmpty) {
        final endTime = DateTime.now();
        final log = SynchronizationLog(
          id: 0,
          startedAt: startTime,
          completedAt: endTime,
          status: 'NO_DATA',
          recordsFound: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorMessage:
              'No official PCSO draws found. Fake fallback is disabled. Paste official table/HTML from pcso.gov.ph to import.',
          sourceUrl: 'https://www.pcso.gov.ph/searchlottoresult.aspx',
        );
        await _syncRepo.insertLog(log);
        return SyncSummary(
          recordsFound: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          status: 'NO_DATA',
          errorMessage:
              'No official draws found from PCSO portal. Access may be restricted by firewall. Copy and paste the official table from pcso.gov.ph into the HTML / Table import box.',
        );
      }

      found = rawDraws.length;
      final lottoTypes = await _typeRepo.getAll();
      final typeMap = {for (final t in lottoTypes) t.code: t};

      for (final raw in rawDraws) {
        final rawGame = raw['game']?.toString() ?? '';
        final gameCode = PcsoParser.normalizeGameCode(rawGame);
        if (gameCode == null || !typeMap.containsKey(gameCode)) {
          skipped++;
          continue;
        }

        // Apply game filter if specified
        if (selectedGameCode != null &&
            selectedGameCode != 'ALL' &&
            gameCode != selectedGameCode) {
          skipped++;
          continue;
        }

        final lottoType = typeMap[gameCode]!;
        final rawNumbers = raw['numbers']?.toString() ?? '';
        final numbers = PcsoParser.parseNumbers(rawNumbers);

        if (numbers == null ||
            !PcsoParser.validateAgainstType(lottoType, numbers)) {
          skipped++;
          continue;
        }

        final rawDate =
            raw['draw_date']?.toString() ??
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        final drawDate = PcsoParser.parseDrawDate(rawDate);
        final jackpot = (raw['jackpot'] as num?)?.toDouble() ?? 0.0;
        final winners = (raw['winners'] as num?)?.toInt() ?? 0;

        // Check deduplication
        final existing = await _resultRepo.findExisting(lottoType.id, drawDate);
        if (existing == null) {
          final newResult = LottoResult(
            id: 0,
            lottoTypeId: lottoType.id,
            drawDate: drawDate,
            number1: numbers[0],
            number2: numbers[1],
            number3: numbers[2],
            number4: numbers[3],
            number5: numbers[4],
            number6: numbers[5],
            jackpotPrize: jackpot,
            winners: winners,
            source: 'PCSO',
            sourceUrl: 'https://www.pcso.gov.ph/searchlottoresult.aspx',
            scrapedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _resultRepo.insert(newResult);
          inserted++;

          // Check against saved lucky picks
          await _checkSavedPicksAndNotify(lottoType.id, drawDate, numbers);
        } else {
          // If jackpot or winners changed, update
          if (existing.jackpotPrize != jackpot || existing.winners != winners) {
            final updatedResult = existing.copyWith(
              jackpotPrize: jackpot > 0 ? jackpot : existing.jackpotPrize,
              winners: winners,
              updatedAt: DateTime.now(),
            );
            await _resultRepo.update(updatedResult);
            updated++;
          } else {
            skipped++;
          }
        }
      }

      // Forward genuine official draws to Central SQLite Backend cache only if parsed from manual HTML paste
      if (rawHtmlContent != null && rawHtmlContent.trim().isNotEmpty && rawDraws.isNotEmpty) {
        try {
          final backendPayload = rawDraws.map((d) {
            final gName = d['game']?.toString() ?? '';
            final gCode = PcsoParser.normalizeGameCode(gName) ?? 'LOTTO_6_42';
            return {
              'lotto_code': gCode,
              'game_name': gName,
              'numbers': d['numbers']?.toString() ?? '',
              'draw_date': d['draw_date']?.toString() ?? '',
              'jackpot': (d['jackpot'] as num?)?.toDouble() ?? 0.0,
              'winners': (d['winners'] as num?)?.toInt() ?? 0,
              'source': 'OFFICIAL_IMPORT',
            };
          }).toList();
          await http
              .post(
                Uri.parse(ApiConstants.importEndpoint),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(backendPayload),
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
    } catch (e) {
      error = e.toString();
    }

    final endTime = DateTime.now();
    final status = error == null
        ? (inserted > 0 || updated > 0 ? 'SUCCESS' : 'SUCCESS')
        : 'FAILED';

    final log = SynchronizationLog(
      id: 0,
      startedAt: startTime,
      completedAt: endTime,
      status: status,
      recordsFound: found,
      recordsInserted: inserted,
      recordsUpdated: updated,
      recordsSkipped: skipped,
      errorMessage: error,
      sourceUrl: 'https://www.pcso.gov.ph/searchlottoresult.aspx',
    );

    await _syncRepo.insertLog(log);

    return SyncSummary(
      recordsFound: found,
      recordsInserted: inserted,
      recordsUpdated: updated,
      recordsSkipped: skipped,
      status: status,
      errorMessage: error,
    );
  }

  Future<void> _checkSavedPicksAndNotify(
    int lottoTypeId,
    String drawDate,
    List<int> officialNumbers,
  ) async {
    final uncheckedPicks = await _pickRepo.getUncheckedPicks(
      lottoTypeId,
      drawDate,
    );

    for (final pick in uncheckedPicks) {
      final matches = _pickService.countMatches(pick.numbers, officialNumbers);
      final status = _pickService.determineStatus(matches);

      final updatedPick = pick.copyWith(
        isChecked: true,
        matchCount: matches,
        status: status,
      );
      await _pickRepo.update(updatedPick);

      // Create notification for user
      await _notifRepo.insert(
        InAppNotification(
          id: 0,
          userId: pick.userId,
          title: 'Lotto Draw Result Checked',
          message:
              'Your saved pick for draw $drawDate matched $matches number(s). Status: $status.',
          category: matches >= 3 ? 'MATCH_FOUND' : 'LUCKY_PICK_CHECKED',
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Parses table data copied from PCSO website or HTML
  List<Map<String, dynamic>> _parseRawHtmlOrText(String text) {
    final results = <Map<String, dynamic>>[];

    // Extract table rows: <tr>...<td>...</td>...</tr>
    final rowRegex = RegExp(
      r'<tr[^>]*>(.*?)<\/tr>',
      caseSensitive: false,
      dotAll: true,
    );
    final rowMatches = rowRegex.allMatches(text);

    if (rowMatches.isNotEmpty) {
      for (final r in rowMatches) {
        final rowContent = r.group(1)!;
        final cellRegex = RegExp(
          r'<td[^>]*>(.*?)<\/td>',
          caseSensitive: false,
          dotAll: true,
        );
        final cells = cellRegex.allMatches(rowContent).map((m) {
          return m.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        }).toList();

        if (cells.length >= 4) {
          final game = cells[0];
          final comb = cells[1];
          final date = cells[2];
          final prize = cells[3];
          final winners = cells.length >= 5
              ? PcsoParser.parseWinners(cells[4])
              : 0;

          if (PcsoParser.normalizeGameCode(game) != null) {
            results.add({
              'game': game,
              'numbers': comb,
              'draw_date': date,
              'jackpot': PcsoParser.parseJackpot(prize),
              'winners': winners,
            });
          }
        }
      }
    } else {
      // Plain text tabular parsing (tab-separated or multiple spaces)
      final lines = text.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final parts = trimmed.split(RegExp(r'\t+|\s{2,}'));
        if (parts.length >= 4) {
          final game = parts[0];
          final comb = parts[1];
          final date = parts[2];
          final prize = parts[3];
          final winners = parts.length >= 5
              ? PcsoParser.parseWinners(parts[4])
              : 0;

          if (PcsoParser.normalizeGameCode(game) != null) {
            results.add({
              'game': game,
              'numbers': comb,
              'draw_date': date,
              'jackpot': PcsoParser.parseJackpot(prize),
              'winners': winners,
            });
          }
        }
      }
    }

    return results;
  }

  /// Automatically loads cached official draw results from the central backend SQLite database
  /// (http://localhost:8081/api/pcso-results) into the local database without scraping PCSO.
  /// If local database already has records, only missing draws are batch-inserted.
  Future<int> loadCachedResultsFromBackend({int limit = 1000}) async {
    try {
      final uri = Uri.parse('${ApiConstants.syncEndpoint}?limit=$limit');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return 0;

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return 0;

      final lottoTypes = await _typeRepo.getAll();
      final typeMap = {for (final t in lottoTypes) t.code: t};

      // Query existing draw keys so we never create duplicates
      final existingResults = await _resultRepo.getAll(limit: 5000);
      final existingKeys = {
        for (final r in existingResults) '${r.lottoTypeId}_${r.drawDate}'
      };

      final toInsert = <LottoResult>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final raw = Map<String, dynamic>.from(item);

        final rawGame = raw['game']?.toString() ?? raw['lotto_code']?.toString() ?? '';
        final gameCode = PcsoParser.normalizeGameCode(rawGame) ?? raw['lotto_code']?.toString();
        if (gameCode == null || !typeMap.containsKey(gameCode)) continue;

        final lottoType = typeMap[gameCode]!;
        final rawNumbers = raw['numbers']?.toString() ?? '';
        final numbers = PcsoParser.parseNumbers(rawNumbers);
        if (numbers == null || !PcsoParser.validateAgainstType(lottoType, numbers)) continue;

        final rawDate = raw['draw_date']?.toString() ?? '';
        final drawDate = PcsoParser.parseDrawDate(rawDate);
        final key = '${lottoType.id}_$drawDate';
        if (existingKeys.contains(key)) continue;

        final jackpot = (raw['jackpot'] as num?)?.toDouble() ?? 0.0;
        final winners = (raw['winners'] as num?)?.toInt() ?? 0;

        toInsert.add(LottoResult(
          id: 0,
          lottoTypeId: lottoType.id,
          drawDate: drawDate,
          number1: numbers[0],
          number2: numbers[1],
          number3: numbers[2],
          number4: numbers[3],
          number5: numbers[4],
          number6: numbers[5],
          jackpotPrize: jackpot,
          winners: winners,
          source: raw['source']?.toString() ?? 'PCSO_CENTRAL_DB',
          sourceUrl: 'https://www.pcso.gov.ph/searchlottoresult.aspx',
          scrapedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (toInsert.isNotEmpty) {
        await _resultRepo.insertBatch(toInsert);
        return toInsert.length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

