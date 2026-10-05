import cron from 'node-cron';
import db, { getConfig, setConfig } from './db.js';
import { executeSync } from './sync_engine.js';

// Official PCSO Lotto Draw Schedule (All 6-number lotto draws occur at 9:00 PM PHT)
export const GAME_SCHEDULE = {
  // 0 = Sunday
  0: [
    { code: 'ULTRA_6_58', name: 'Ultra Lotto 6/58', drawDays: 'Tue, Fri, Sun', drawTime: '9:00 PM PHT' },
    { code: 'SUPER_6_49', name: 'Super Lotto 6/49', drawDays: 'Tue, Thu, Sun', drawTime: '9:00 PM PHT' },
  ],
  // 1 = Monday
  1: [
    { code: 'GRAND_6_55', name: 'Grand Lotto 6/55', drawDays: 'Mon, Wed, Sat', drawTime: '9:00 PM PHT' },
    { code: 'MEGA_6_45', name: 'Mega Lotto 6/45', drawDays: 'Mon, Wed, Fri', drawTime: '9:00 PM PHT' },
  ],
  // 2 = Tuesday
  2: [
    { code: 'ULTRA_6_58', name: 'Ultra Lotto 6/58', drawDays: 'Tue, Fri, Sun', drawTime: '9:00 PM PHT' },
    { code: 'SUPER_6_49', name: 'Super Lotto 6/49', drawDays: 'Tue, Thu, Sun', drawTime: '9:00 PM PHT' },
    { code: 'LOTTO_6_42', name: 'Lotto 6/42', drawDays: 'Tue, Thu, Sat', drawTime: '9:00 PM PHT' },
  ],
  // 3 = Wednesday
  3: [
    { code: 'GRAND_6_55', name: 'Grand Lotto 6/55', drawDays: 'Mon, Wed, Sat', drawTime: '9:00 PM PHT' },
    { code: 'MEGA_6_45', name: 'Mega Lotto 6/45', drawDays: 'Mon, Wed, Fri', drawTime: '9:00 PM PHT' },
  ],
  // 4 = Thursday
  4: [
    { code: 'SUPER_6_49', name: 'Super Lotto 6/49', drawDays: 'Tue, Thu, Sun', drawTime: '9:00 PM PHT' },
    { code: 'LOTTO_6_42', name: 'Lotto 6/42', drawDays: 'Tue, Thu, Sat', drawTime: '9:00 PM PHT' },
  ],
  // 5 = Friday
  5: [
    { code: 'ULTRA_6_58', name: 'Ultra Lotto 6/58', drawDays: 'Tue, Fri, Sun', drawTime: '9:00 PM PHT' },
    { code: 'MEGA_6_45', name: 'Mega Lotto 6/45', drawDays: 'Mon, Wed, Fri', drawTime: '9:00 PM PHT' },
  ],
  // 6 = Saturday
  6: [
    { code: 'GRAND_6_55', name: 'Grand Lotto 6/55', drawDays: 'Mon, Wed, Sat', drawTime: '9:00 PM PHT' },
    { code: 'LOTTO_6_42', name: 'Lotto 6/42', drawDays: 'Tue, Thu, Sat', drawTime: '9:00 PM PHT' },
  ],
};

const DAY_NAMES = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

let activeCronTasks = [];

/**
 * Returns current date and time formatted in Philippine Standard Time (PHT, UTC+8)
 */
export function getPhtDate() {
  const now = new Date();
  const phtString = now.toLocaleString('en-US', { timeZone: 'Asia/Manila' });
  const phtDate = new Date(phtString);

  const year = phtDate.getFullYear();
  const month = String(phtDate.getMonth() + 1).padStart(2, '0');
  const day = String(phtDate.getDate()).padStart(2, '0');
  const dateStr = `${year}-${month}-${day}`;
  const dayOfWeek = phtDate.getDay();
  const dayName = DAY_NAMES[dayOfWeek];
  const phtTimeStr = phtDate.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' });

  return { dateStr, dayOfWeek, dayName, phtTimeStr, phtDate };
}

/**
 * Checks if auto-scrape schedule is enabled in system_config
 */
export function isAutoScrapeEnabled() {
  return getConfig('auto_scrape_enabled', 'true') === 'true';
}

/**
 * Sets auto-scrape status and reconfigures active cron jobs
 */
export function setAutoScrapeEnabled(enabled, onLog = console.log) {
  const strVal = enabled ? 'true' : 'false';
  setConfig('auto_scrape_enabled', strVal);
  if (enabled) {
    onLog('[Auto-Scheduler] Automated post-draw PCSO scraping has been ENABLED.');
    startCronJobs(onLog);
  } else {
    onLog('[Auto-Scheduler] Automated post-draw PCSO scraping has been PAUSED / DISABLED.');
    stopCronJobs();
  }
  return isAutoScrapeEnabled();
}

/**
 * Starts cron jobs for post-draw scraping:
 * - 9:30 PM PHT (30 minutes after official 9:00 PM draw)
 * - 10:15 PM PHT (Secondary verification & retry check)
 */
function startCronJobs(onLog = console.log) {
  stopCronJobs();

  if (!isAutoScrapeEnabled()) {
    onLog('[Auto-Scheduler] Auto-scrape is disabled in system config. Cron not registered.');
    return;
  }

  // Trigger 1: 9:30 PM (21:30) PHT daily
  const task1 = cron.schedule('30 21 * * *', async () => {
    if (!isAutoScrapeEnabled()) return;
    onLog('[Scheduled Cron] 9:30 PM PHT reached — running post-draw auto-scraper for today\'s games...');
    await runAutoScrapeForToday(onLog);
  }, { timezone: 'Asia/Manila' });

  // Trigger 2: 10:15 PM (22:15) PHT daily
  const task2 = cron.schedule('15 22 * * *', async () => {
    if (!isAutoScrapeEnabled()) return;
    onLog('[Scheduled Cron] 10:15 PM PHT reached — running post-draw secondary verification check...');
    await runAutoScrapeForToday(onLog);
  }, { timezone: 'Asia/Manila' });

  activeCronTasks = [task1, task2];
  onLog('[Auto-Scheduler] Active triggers scheduled: 9:30 PM & 10:15 PM PHT daily.');
}

/**
 * Stops all registered cron jobs
 */
function stopCronJobs() {
  for (const t of activeCronTasks) {
    try { t.stop(); } catch (_) {}
  }
  activeCronTasks = [];
}

/**
 * Executes post-draw scraping specifically targeted for today's active games
 */
export async function runAutoScrapeForToday(onLog = console.log) {
  const { dateStr, dayOfWeek, dayName, phtTimeStr } = getPhtDate();
  const activeGames = GAME_SCHEDULE[dayOfWeek] || [];
  const gameNames = activeGames.map(g => g.name).join(', ');

  onLog('================================================================');
  onLog(`[Auto-Scrape Engine] 🕒 Post-Draw Scheduled Scraping Triggered at ${phtTimeStr} PHT`);
  onLog(`[Auto-Scrape Engine] 📅 Target Date: ${dayName}, ${dateStr} (PHT)`);
  onLog(`[Auto-Scrape Engine] 🎯 Scheduled Games for Today (${dayName}):`);
  activeGames.forEach(g => {
    onLog(`   • ${g.name} (${g.code}) [Draw: ${g.drawTime}]`);
  });

  // Query PCSO portal for recent draws (last 3 days up to today)
  const threeDaysAgo = new Date(Date.now() - 3 * 86400000);
  const fromY = threeDaysAgo.getFullYear();
  const fromM = String(threeDaysAgo.getMonth() + 1).padStart(2, '0');
  const fromD = String(threeDaysAgo.getDate()).padStart(2, '0');
  const fromDateStr = `${fromY}-${fromM}-${fromD}`;

  onLog(`[Auto-Scrape Engine] Querying PCSO official portal (From: ${fromDateStr} To: ${dateStr})...`);

  const summary = await executeSync({
    runType: 'AUTO_POST_DRAW',
    fromDate: fromDateStr,
    toDate: dateStr,
    gameFilter: 'ALL',
    onLog,
  });

  // Verify which of today's scheduled games were found
  if (summary.draws && summary.draws.length > 0) {
    const todayDraws = summary.draws.filter(d => d.draw_date === dateStr);
    onLog(`[Auto-Scrape Engine] ${todayDraws.length} draw result(s) confirmed for today (${dateStr}).`);
    for (const g of activeGames) {
      const match = todayDraws.find(d => d.lotto_code === g.code);
      if (match) {
        onLog(`   ✓ [MATCH FOUND] ${g.name}: Numbers: [${match.numbers}], Jackpot: ₱${match.jackpot.toLocaleString()}, Winners: ${match.winners}`);
      } else {
        onLog(`   ⏳ [PENDING] ${g.name}: Not yet uploaded by PCSO for ${dateStr}. (Will re-check at 10:15 PM)`);
      }
    }
  } else {
    onLog(`[Auto-Scrape Engine] No new official results found on PCSO portal for ${dateStr} yet.`);
  }

  onLog('================================================================');
  return summary;
}

/**
 * Initializes the auto scheduler at server startup
 */
export function initAutoScraper(onLog = console.log) {
  const enabled = isAutoScrapeEnabled();
  const { dateStr, dayName, phtTimeStr, dayOfWeek } = getPhtDate();
  const activeGames = GAME_SCHEDULE[dayOfWeek] || [];

  onLog(`[Auto-Scheduler] Current Time: ${dateStr} ${phtTimeStr} PHT (${dayName}).`);
  onLog(`[Auto-Scheduler] Today's 9:00 PM Games: ${activeGames.map(g => g.name).join(', ')}.`);
  if (enabled) {
    onLog('[Auto-Scheduler] Status: ENABLED. Post-draw scraping active at 9:30 PM & 10:15 PM PHT.');
    startCronJobs(onLog);
  } else {
    onLog('[Auto-Scheduler] Status: DISABLED. Auto-scraping is paused.');
  }
}

/**
 * Returns comprehensive auto-scheduler status for REST API
 */
export function getAutoScrapeStatus() {
  const enabled = isAutoScrapeEnabled();
  const { dateStr, dayOfWeek, dayName, phtTimeStr } = getPhtDate();
  const activeGamesToday = GAME_SCHEDULE[dayOfWeek] || [];

  // Query last auto-scrape run from sync_history
  const lastAutoRun = db.prepare(`
    SELECT * FROM sync_history
    WHERE run_type = 'AUTO_POST_DRAW'
    ORDER BY id DESC LIMIT 1
  `).get() || null;

  return {
    enabled,
    timezone: 'Asia/Manila (PHT, UTC+8)',
    currentPhtTime: phtTimeStr,
    todayDate: dateStr,
    dayName,
    drawTime: '9:00 PM PHT',
    scheduledScrapeTimes: ['9:30 PM PHT (Primary)', '10:15 PM PHT (Retry/Confirm)'],
    cronExpressions: ['30 21 * * *', '15 22 * * *'],
    activeGamesToday,
    lastAutoRun,
    weeklySchedule: GAME_SCHEDULE,
  };
}

