import { chromium } from 'playwright';

// Supported 5 PCSO 6-number games
const SUPPORTED_GAMES = [
  { code: 'ULTRA_6_58', name: 'Ultra Lotto 6/58', aliases: ['6/58', 'ULTRA'] },
  { code: 'GRAND_6_55', name: 'Grand Lotto 6/55', aliases: ['6/55', 'GRAND'] },
  { code: 'SUPER_6_49', name: 'Super Lotto 6/49', aliases: ['6/49', 'SUPER'] },
  { code: 'MEGA_6_45', name: 'Mega Lotto 6/45', aliases: ['6/45', 'MEGA'] },
  { code: 'LOTTO_6_42', name: 'Lotto 6/42', aliases: ['6/42', 'LOTTO 6/42', '642'] },
];

export function identifyGame(rawText) {
  if (!rawText) return null;
  const upper = rawText.toUpperCase().trim();
  for (const g of SUPPORTED_GAMES) {
    if (upper.includes(g.code)) return g;
    for (const alias of g.aliases) {
      if (upper.includes(alias)) return g;
    }
  }
  return null;
}

export function normalizeDate(rawDate) {
  if (!rawDate) return null;
  const clean = rawDate.trim();
  const slashParts = clean.split('/');
  if (slashParts.length === 3) {
    const month = slashParts[0].padStart(2, '0');
    const day = slashParts[1].padStart(2, '0');
    const year = slashParts[2];
    return `${year}-${month}-${day}`;
  }
  if (/^\d{4}-\d{2}-\d{2}$/.test(clean)) {
    return clean;
  }
  return clean;
}

export function parseNumbers(rawNumbers) {
  if (!rawNumbers) return null;
  const parts = rawNumbers.split(/[^0-9]+/).filter(Boolean).map(n => parseInt(n, 10));
  if (parts.length === 6 && parts.every(n => !isNaN(n) && n > 0 && n <= 58)) {
    // Preserve original scraped order without sorting
    return parts.map(n => n.toString().padStart(2, '0')).join('-');
  }
  return null;
}

/**
 * Executes scraping via Playwright headless Chromium
 */
export async function scrapeFromPcsoPortal({ fromDate, toDate, gameFilter, onLog = console.log }) {
  const pcsoUrl = 'https://www.pcso.gov.ph/searchlottoresult.aspx';
  onLog(`[Playwright Worker] Launching headless browser for ${pcsoUrl}...`);

  let browser;
  try {
    browser = await chromium.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-blink-features=AutomationControlled',
      ],
    });

    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      viewport: { width: 1280, height: 800 },
      locale: 'en-US',
    });

    const page = await context.newPage();
    page.setDefaultTimeout(15000);

    onLog(`[Playwright Worker] Navigating to PCSO official portal...`);
    const response = await page.goto(pcsoUrl, { waitUntil: 'domcontentloaded' });
    const status = response ? response.status() : 'N/A';
    onLog(`[Playwright Worker] Portal response status: ${status}`);

    await page.waitForTimeout(1500);

    const extractedRows = await page.evaluate(() => {
      const rows = [];
      const trElements = document.querySelectorAll('table tr');
      for (const tr of trElements) {
        const tds = tr.querySelectorAll('td');
        if (tds.length >= 4) {
          const cells = Array.from(tds).map(td => td.innerText.trim());
          rows.push(cells);
        }
      }
      return rows;
    });

    onLog(`[Playwright Worker] Found ${extractedRows.length} raw table rows on portal page.`);

    const results = [];
    for (const cells of extractedRows) {
      if (cells.length < 4) continue;
      const gameText = cells[0];
      const numbersText = cells[1];
      const drawDateText = cells[2];
      const jackpotText = cells[3];
      const winnersText = cells.length >= 5 ? cells[4] : '0';

      const gameObj = identifyGame(gameText);
      if (!gameObj) continue;

      if (gameFilter && gameFilter !== 'ALL' && gameObj.code !== gameFilter) {
        continue;
      }

      const validNumbers = parseNumbers(numbersText);
      if (!validNumbers) continue;

      const normalizedDate = normalizeDate(drawDateText);
      if (!normalizedDate) continue;

      const cleanJackpot = parseFloat(jackpotText.replace(/[^0-9.]/g, '')) || 0.0;
      const cleanWinners = parseInt(winnersText.replace(/[^0-9]/g, ''), 10) || 0;

      results.push({
        lotto_code: gameObj.code,
        game_name: gameObj.name,
        numbers: validNumbers,
        draw_date: normalizedDate,
        jackpot: cleanJackpot,
        winners: cleanWinners,
        source: 'PCSO_PLAYWRIGHT_LIVE',
      });
    }

    await browser.close();
    return results;
  } catch (err) {
    if (browser) {
      try { await browser.close(); } catch (_) {}
    }
    onLog(`[Playwright Worker] Akamai WAF / Portal Notice: ${err.message}`);
    return null;
  }
}

