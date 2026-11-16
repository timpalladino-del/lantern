// node render-linux.js [page.html] [fps]
// Linux or cloud renderer: headless Chromium through Playwright, four pages in parallel,
// one PNG per frame into frames/. The page must expose window.TOTAL and seek(t).
const { chromium } = require('playwright');
const path = require('path'), fs = require('fs');
const page = process.argv[2] || 'vox.html', fps = Number(process.argv[3] || 30), WORKERS = 4;
(async () => {
  const b = await chromium.launch();
  fs.mkdirSync(path.join(__dirname, 'frames'), { recursive: true });
  const mk = async () => { const p = await b.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
    await p.goto('file://' + path.join(__dirname, page)); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(1000);
    await p.evaluate(() => Promise.all([...document.images].map(i => i.decode ? i.decode().catch(() => {}) : 0))); return p; };
  const pages = await Promise.all(Array.from({ length: WORKERS }, mk));
  const total = await pages[0].evaluate(() => window.TOTAL);
  const broken = await pages[0].evaluate(() => [...document.images].filter(i => !i.naturalWidth).map(i => i.src));
  if (broken.length) { console.log('missing images', broken); process.exit(2); }
  const N = Math.round(total * fps); let next = 0; const t0 = Date.now();
  await Promise.all(pages.map(async (p) => { for (;;) { const n = next++; if (n >= N) break;
    await p.evaluate(x => seek(x), n / fps);
    await p.screenshot({ path: path.join(__dirname, 'frames', 'f' + String(n).padStart(5, '0') + '.png') });
    if (n % 200 === 0) console.log('frame', n, ((Date.now() - t0) / 1000).toFixed(0) + 's'); } }));
  console.log('done', N, 'frames', ((Date.now() - t0) / 1000).toFixed(0) + 's');
  await b.close();
})().catch(e => { console.log('ERR', e); process.exit(1); });
