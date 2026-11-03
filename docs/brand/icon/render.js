const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1024, height: 1024 }, deviceScaleFactor: 1 });
  for (const name of ['lantern-icon', 'lantern-icon-dark', 'lantern-icon-tinted']) {
    const svg = fs.readFileSync(path.join(__dirname, name + '.svg'), 'utf8');
    await page.setContent(`<html><body style="margin:0">${svg}</body></html>`);
    await page.screenshot({ path: path.join(__dirname, name + '-1024.png'), clip: { x: 0, y: 0, width: 1024, height: 1024 } });
  }
  // Preview sheet: home-screen sizes, light and dark wallpaper, all appearance modes.
  const svgs = {};
  for (const n of ['lantern-icon', 'lantern-icon-dark', 'lantern-icon-tinted', 'lantern-icon-clearpreview']) {
    svgs[n] = 'data:image/svg+xml;base64,' + Buffer.from(fs.readFileSync(path.join(__dirname, n + '.svg'))).toString('base64');
  }
  const sizes = [180, 120, 76, 60, 40, 29];
  const icon = (src, s) => `<img src="${src}" style="width:${s}px;height:${s}px;border-radius:${Math.round(s*0.2237)}px;display:block">`;
  const row = (label, src, bg, fg) => `
    <div style="background:${bg};color:${fg};padding:28px 32px;display:flex;gap:28px;align-items:flex-end;font:500 13px -apple-system,Helvetica,Arial">
      <div style="width:150px;font-size:14px;opacity:.85">${label}</div>
      ${sizes.map(s => `<div style="text-align:center">${icon(src, s)}<div style="margin-top:8px;opacity:.6;font-size:11px">${s}px</div></div>`).join('')}
    </div>`;
  const html = `<html><body style="margin:0;width:1100px;background:#fff">
    ${row('Default · light wallpaper', svgs['lantern-icon'], '#E9ECF2', '#1A2232')}
    ${row('Default · dark wallpaper', svgs['lantern-icon'], '#1C2230', '#F2F4F7')}
    ${row('Dark appearance', svgs['lantern-icon-dark'], '#0D1118', '#F2F4F7')}
    ${row('Tinted (system applies the user tint)', svgs['lantern-icon-tinted'], '#2A3449', '#F2F4F7')}
    ${row('Clear (glass silhouette, preview)', svgs['lantern-icon-clearpreview'], '#8B94A6', '#F2F4F7')}
    <div style="padding:16px 32px;font:12px -apple-system,Helvetica,Arial;color:#5F6B7F">Corner radius approximates the iOS mask; the system applies the real one. Liquid Glass lighting is not simulated here.</div>
  </body></html>`;
  const p2 = await browser.newPage({ viewport: { width: 1100, height: 10 }, deviceScaleFactor: 2 });
  await p2.setContent(html);
  await p2.screenshot({ path: path.join(__dirname, 'icon-preview-sheet.png'), fullPage: true });
  await browser.close();
  console.log('rendered');
})();
