// node render.js [fps] [start] [end]
// Opens comp.html in a new tab of the debug Chrome (port 9333), sizes it to 1080x1920,
// and screenshots one frame per 1/fps second into frames/f%05d.png. Pure CDP, no packages.
const fs = require('fs');
const path = require('path');
const dir = __dirname;
const fps = Number(process.argv[2] || 30);
async function json(u, m = 'GET') { const r = await fetch(u, { method: m }); return r.json(); }
function connect(ws) {
  return new Promise((res, rej) => {
    const s = new WebSocket(ws); let id = 0; const waiting = {};
    s.onopen = () => res({ send: (method, params = {}) => new Promise((ok, no) => { const i = ++id; waiting[i] = { ok, no }; s.send(JSON.stringify({ id: i, method, params })); }), close: () => s.close() });
    s.onmessage = (m) => { const d = JSON.parse(m.data); if (d.id && waiting[d.id]) { const w = waiting[d.id]; delete waiting[d.id]; d.error ? w.no(new Error(JSON.stringify(d.error))) : w.ok(d.result); } };
    s.onerror = (e) => rej(e);
  });
}
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
(async () => {
  const url = 'file://' + path.join(dir, 'comp.html');
  const t = await json('http://127.0.0.1:9333/json/new?' + encodeURIComponent(url), 'PUT');
  const c = await connect(t.webSocketDebuggerUrl);
  await c.send('Page.enable');
  await c.send('Emulation.setDeviceMetricsOverride', { width: 1080, height: 1920, deviceScaleFactor: 1, mobile: false });
  await sleep(1500);
  await c.send('Runtime.evaluate', { expression: 'document.fonts.ready.then(() => true)', awaitPromise: true });
  await sleep(800);
  const total = (await c.send('Runtime.evaluate', { expression: 'window.TOTAL', returnByValue: true })).result.value;
  const start = Number(process.argv[3] || 0), end = Number(process.argv[4] || total);
  const n0 = Math.round(start * fps), n1 = Math.round(end * fps);
  console.log('total', total, 'frames', n0, '..', n1);
  fs.mkdirSync(path.join(dir, 'frames'), { recursive: true });
  const t0 = Date.now();
  for (let n = n0; n < n1; n++) {
    const tt = n / fps;
    await c.send('Runtime.evaluate', { expression: `seek(${tt})`, returnByValue: true });
    const shot = await c.send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
    fs.writeFileSync(path.join(dir, 'frames', 'f' + String(n).padStart(5, '0') + '.png'), Buffer.from(shot.data, 'base64'));
    if (n % 150 === 0) console.log('frame', n, 't', tt.toFixed(2), 'elapsed', ((Date.now() - t0) / 1000).toFixed(0) + 's');
  }
  console.log('done', n1 - n0, 'frames in', ((Date.now() - t0) / 1000).toFixed(0) + 's');
  try { await fetch('http://127.0.0.1:9333/json/close/' + t.id); } catch (e) {}
  c.close();
})().catch(e => { console.log('ERR', e.message); process.exit(1); });
