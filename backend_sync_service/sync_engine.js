import db from './db.js';
import { scrapeFromPcsoPortal, identifyGame, parseNumbers, normalizeDate } from './scraper.js';

export function persistDraws(draws) {
  if (!draws || draws.length === 0) {
    return { inserted: 0, updated: 0 };
  }

  const insertStmt = db.prepare(`
    INSERT INTO official_lotto_results (lotto_code, game_name, numbers, draw_date, jackpot, winners, source)
    VALUES (@lotto_code, @game_name, @numbers, @draw_date, @jackpot, @winners, @source)
    ON CONFLICT(lotto_code, draw_date) DO UPDATE SET
      numbers = excluded.numbers,
      jackpot = excluded.jackpot,
      winners = excluded.winners,
      source = excluded.source,
      scraped_at = CURRENT_TIMESTAMP
  `);

  const tx = db.transaction((rows) => {
    let inserted = 0;
    let updated = 0;
    for (const row of rows) {
      const existing = db.prepare('SELECT id, numbers, winners, jackpot FROM official_lotto_results WHERE lotto_code = ? AND draw_date = ?').get(row.lotto_code, row.draw_date);
      insertStmt.run(row);
      if (existing) {
        if (existing.winners !== row.winners || existing.jackpot !== row.jackpot || existing.numbers !== row.numbers) {
          updated++;
        }
      } else {
        inserted++;
      }
    }
    return { inserted, updated };
  });

  return tx(draws);
}

export async function executeSync({ runType = 'ON_DEMAND', fromDate, toDate, gameFilter, onLog = console.log } = {}) {
  const startTime = new Date().toISOString();
  onLog(`[Sync Engine] Starting ${runType} sync for range: ${fromDate || 'all'} -> ${toDate || 'today'}...`);

  const draws = await scrapeFromPcsoPortal({ fromDate, toDate, gameFilter, onLog });

  if (!draws || draws.length === 0) {
    onLog('[Sync Engine] No official draws returned from PCSO portal. 0 records inserted. No fake fallback applied.');
    const endTime = new Date().toISOString();
    db.prepare(`
      INSERT INTO sync_history (run_type, started_at, completed_at, status, records_found, records_inserted, records_updated, records_skipped, error_message)
      VALUES (?, ?, ?, 'NO_DATA', 0, 0, 0, 0, ?)
    `).run(runType, startTime, endTime, 'PCSO portal returned 0 records or access was restricted. No fake fallback applied.');

    return {
      status: 'NO_DATA',
      recordsFound: 0,
      recordsInserted: 0,
      recordsUpdated: 0,
      recordsSkipped: 0,
      draws: [],
      message: 'No official draws returned from PCSO portal. Access may be restricted. No fake fallback applied.',
    };
  }

  onLog(`[Sync Engine] Saving ${draws.length} verified official draw records into SQLite cache...`);
  const { inserted, updated } = persistDraws(draws);
  const endTime = new Date().toISOString();

  db.prepare(`
    INSERT INTO sync_history (run_type, started_at, completed_at, status, records_found, records_inserted, records_updated, records_skipped)
    VALUES (?, ?, ?, 'SUCCESS', ?, ?, ?, ?)
  `).run(runType, startTime, endTime, draws.length, inserted, updated, draws.length - (inserted + updated));

  onLog(`[Sync Engine] Synchronization finished! Stored: ${draws.length} draws (New: ${inserted}, Updated: ${updated}).`);
  return {
    status: 'SUCCESS',
    recordsFound: draws.length,
    recordsInserted: inserted,
    recordsUpdated: updated,
    recordsSkipped: draws.length - (inserted + updated),
    draws,
  };
}

