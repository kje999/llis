import { chromium } from 'playwright';

// Supported 5 PCSO 6-number games
const SUPPORTED_GAMES = [
  { code: 'ULTRA_6_58', name: 'Ultra Lotto 6/58', aliases: ['6/58', 'ULTRA'], pcsoVal: '18' },
  { code: 'GRAND_6_55', name: 'Grand Lotto 6/55', aliases: ['6/55', 'GRAND'], pcsoVal: '17' },
  { code: 'SUPER_6_49', name: 'Super Lotto 6/49', aliases: ['6/49', 'SUPER', 'SUPERLOTTO'], pcsoVal: '1' },
  { code: 'MEGA_6_45', name: 'Mega Lotto 6/45', aliases: ['6/45', 'MEGA', 'MEGALOTTO'], pcsoVal: '2' },
  { code: 'LOTTO_6_42', name: 'Lotto 6/42', aliases: ['6/42', 'LOTTO 6/42', '642'], pcsoVal: '13' },
];

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
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

function parseTableFromHtml(html) {
  const rows = [];
  const tableMatch = html.match(/<table[^>]*class="[^"]*search-lotto-result-table[^"]*"[^>]*>([\s\S]*?)<\/table>/i) ||
                     html.match(/<table[^>]*id="[^"]*GridView1[^"]*"[^>]*>([\s\S]*?)<\/table>/i) ||
                     html.match(/<table[\s\S]*?<\/table>/i);

  if (!tableMatch) return rows;

  const tableHtml = tableMatch[0];
  const trMatches = tableHtml.match(/<tr[\s\S]*?<\/tr>/gi) || [];

  for (const tr of trMatches) {
    const tdMatches = tr.match(/<t[dh][^>]*>([\s\S]*?)<\/t[dh]>/gi) || [];
    if (tdMatches.length >= 4) {
      const cells = tdMatches.map(cell => cell.replace(/<[^>]+>/g, '').trim());
      rows.push(cells);
    }
  }
  return rows;
}

function filterAndNormalizeRows(extractedRows, gameFilter) {
  const results = [];
  for (const cells of extractedRows) {
    if (cells.length < 4) continue;
    const gameText = cells[0];
    const numbersText = cells[1];
    const drawDateText = cells[2];
    const jackpotText = cells[3];
    const winnersText = cells.length >= 5 ? cells[4] : '0';

    const gameObj = identifyGame(gameText);
    if (!gameObj) continue; // Strictly supports only the 5 PCSO 6-number lotto games

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
      source: 'PCSO_PORTAL_LIVE',
    });
  }
  return results;
}

/**
 * Executes authentic scraping from PCSO official portal with full date-range search capability.
 * Triggered ONLY on demand when the user presses 'SEARCH & SCRAPE PCSO'.
 */
export async function scrapeFromPcsoPortal({ fromDate, toDate, gameFilter, onLog = console.log } = {}) {
  const pcsoUrl = 'https://www.pcso.gov.ph/searchlottoresult.aspx';
  onLog(`[Official PCSO Scraper] Button pressed! Connecting to official portal at ${pcsoUrl}...`);

  const browserHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Sec-Ch-Ua': '"Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"',
    'Sec-Ch-Ua-Mobile': '?0',
    'Sec-Ch-Ua-Platform': '"Windows"',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-User': '?1',
    'Upgrade-Insecure-Requests': '1',
  };

  try {
    // 1. Initial GET to obtain ASP.NET session tokens (__VIEWSTATE, __EVENTVALIDATION)
    const getRes = await fetch(pcsoUrl, {
      headers: browserHeaders,
      signal: AbortSignal.timeout(12000),
    });

    if (!getRes.ok) {
      throw new Error(`Portal GET returned HTTP ${getRes.status}`);
    }

    const initialHtml = await getRes.text();
    const vs = (initialHtml.match(/id="__VIEWSTATE"\s+value="([^"]+)"/i) || [])[1];
    const vsg = (initialHtml.match(/id="__VIEWSTATEGENERATOR"\s+value="([^"]+)"/i) || [])[1];
    const ev = (initialHtml.match(/id="__EVENTVALIDATION"\s+value="([^"]+)"/i) || [])[1];

    if (!vs || !ev) {
      onLog(`[Official PCSO Scraper] Notice: Form tokens missing in portal page. Parsing default table...`);
      const defaultRows = parseTableFromHtml(initialHtml);
      return filterAndNormalizeRows(defaultRows, gameFilter);
    }

    // 2. Format search date range parameters
    const start = fromDate ? new Date(fromDate) : new Date(Date.now() - 365 * 86400000);
    const end = toDate ? new Date(toDate) : new Date();

    const startMonth = MONTH_NAMES[start.getMonth()] || 'October';
    const startDate = start.getDate().toString();
    const startYear = start.getFullYear().toString();

    const endMonth = MONTH_NAMES[end.getMonth()] || 'October';
    const endDate = end.getDate().toString();
    const endYear = end.getFullYear().toString();

    let gameVal = '0';
    if (gameFilter && gameFilter !== 'ALL') {
      const match = SUPPORTED_GAMES.find(g => g.code === gameFilter);
      if (match) gameVal = match.pcsoVal;
    }

    onLog(`[Official PCSO Scraper] Querying PCSO range: ${startMonth} ${startDate}, ${startYear} to ${endMonth} ${endDate}, ${endYear} (Game Code: ${gameFilter || 'ALL'})...`);

    const formParams = new URLSearchParams();
    formParams.append('__EVENTTARGET', '');
    formParams.append('__EVENTARGUMENT', '');
    formParams.append('__VIEWSTATE', vs);
    if (vsg) formParams.append('__VIEWSTATEGENERATOR', vsg);
    formParams.append('__EVENTVALIDATION', ev);
    formParams.append('ctl00$ctl00$cphContainer$cpContent$ddlStartMonth', startMonth);
    formParams.append('ctl00$ctl00$cphContainer$cpContent$ddlStartDate', startDate);
    formParams.append('ctl00$ctl00$cphContainer$cpContent$ddlStartYear', startYear);
    formParams.append('ctl00$ctl00$cphContainer$cpContent$ddlEndMonth', endMonth);
    formParams.append('ctl00$ctl00$cphContainer$cpContent$ddlEndDay', endDate);
    formParams.append('ctl00$ctl00$cphContainer$cpContent$ddlEndYear', endYear);
    formParams.append('ctl00$ctl00$cphContainer$cpContent$ddlSelectGame', gameVal);
    formParams.append('ctl00$ctl00$cphContainer$cpContent$btnSearch', 'Search Lotto');

    // 3. Post search form to official PCSO ASP.NET portal
    const postRes = await fetch(pcsoUrl, {
      method: 'POST',
      headers: {
        ...browserHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Origin': 'https://www.pcso.gov.ph',
        'Referer': pcsoUrl,
      },
      body: formParams.toString(),
      signal: AbortSignal.timeout(20000),
    });

    onLog(`[Official PCSO Scraper] Portal search response status: ${postRes.status}`);

    if (postRes.ok) {
      const resultHtml = await postRes.text();
      const extractedRows = parseTableFromHtml(resultHtml);
      onLog(`[Official PCSO Scraper] Extracted ${extractedRows.length} total raw table rows for requested period.`);

      const results = filterAndNormalizeRows(extractedRows, gameFilter);
      onLog(`[Official PCSO Scraper] Filtered & normalized ${results.length} official 6-number lotto records.`);
      return results;
    }
  } catch (err) {
    onLog(`[Official PCSO Scraper] Notice: ${err.message}. Trying Playwright engine...`);
  }

  // 4. Secondary Playwright Fallback if HTTP POST encounters unexpected error
  let browser;
  try {
    browser = await chromium.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });

    const context = await browser.newContext({ userAgent: browserHeaders['User-Agent'] });
    const page = await context.newPage();
    page.setDefaultTimeout(15000);

    onLog(`[Playwright Worker] Navigating to PCSO official portal...`);
    await page.goto(pcsoUrl, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    const pageHtml = await page.content();
    const extractedRows = parseTableFromHtml(pageHtml);
    await browser.close();
    return filterAndNormalizeRows(extractedRows, gameFilter);
  } catch (err) {
    if (browser) {
      try { await browser.close(); } catch (_) {}
    }
    onLog(`[Playwright Worker] Notice: ${err.message}`);
    return [];
  }
}
