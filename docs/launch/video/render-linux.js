// node render-linux.js [page.html] [fps]
// Linux or cloud renderer: headless Chromium through Playwright, one PNG per frame into frames/.
// It starts four copies of itself, one browser each, because a single browser composites every
// page in one process and renders about four times slower. The page must expose window.TOTAL and seek(t).
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path'), fs = require('fs');
const page = process.argv[2] || 'vox.html', fps = Number(process.argv[3] || 30), WORKERS = 4;
const worker = process.argv[4] === undefined ? null : Number(process.argv[4]);
if (worker === null) {
  fs.mkdirSync(path.join(__dirname, 'frames'), { recursive: true });
  let left = WORKERS, failed = false; const t0 = Date.now();
  for (let w = 0; w < WORKERS; w++) spawn(process.execPath, [__filename, page, String(fps), String(w)], { stdio: 'inherit' })
    .on('exit', code => { if (code) failed = true; if (--left === 0) { console.log(failed ? 'FAILED' : 'done', ((Date.now() - t0) / 1000).toFixed(0) + 's'); process.exit(failed ? 1 : 0); } });
} else (async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  await p.goto('file://' + path.join(__dirname, page)); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(1000);
  await p.evaluate(() => Promise.all([...document.images].map(i => i.decode ? i.decode().catch(() => {}) : 0)));
  const broken = await p.evaluate(() => [...document.images].filter(i => !i.naturalWidth).map(i => i.src));
  if (broken.length) { console.log('missing images', broken); process.exit(2); }
  const N = Math.round((await p.evaluate(() => window.TOTAL)) * fps);
  for (let n = worker; n < N; n += WORKERS) { await p.evaluate(x => seek(x), n / fps);
    await p.screenshot({ path: path.join(__dirname, 'frames', 'f' + String(n).padStart(5, '0') + '.png') }); }
  await b.close();
})().catch(e => { console.log('ERR', e); process.exit(1); });
