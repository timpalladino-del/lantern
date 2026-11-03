const { chromium } = require('playwright'); const fs = require('fs');
const icon = 'data:image/png;base64,' + fs.readFileSync('icon.png').toString('base64');
const page = (w, h, variant) => `<html><head>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,700&family=Nunito+Sans:opsz,wght@6..12,500;6..12,700&display=swap">
<style>
 body{margin:0;width:${w}px;height:${h}px;background:#141B2B;color:#F2F4F7;font-family:"Nunito Sans","Helvetica Neue",Arial,sans-serif;overflow:hidden;position:relative}
 .glow{position:absolute;left:50%;top:${variant==='square'?'38%':'50%'};width:${variant==='square'?'900px':'760px'};height:${variant==='square'?'900px':'760px'};transform:translate(-50%,-50%);border-radius:50%;background:radial-gradient(circle,rgba(245,176,65,.28) 0%,rgba(245,176,65,.08) 45%,rgba(245,176,65,0) 70%)}
 .wrap{position:absolute;inset:0;display:flex;flex-direction:${variant==='square'?'column':'row'};align-items:center;justify-content:center;gap:${variant==='square'?'28px':'64px'};padding:72px;box-sizing:border-box}
 .icon{width:${variant==='square'?'360px':'300px'};height:${variant==='square'?'360px':'300px'};border-radius:22.37%;box-shadow:0 30px 80px rgba(0,0,0,.45);flex:none}
 .text{display:flex;flex-direction:column;align-items:${variant==='square'?'center':'flex-start'};text-align:${variant==='square'?'center':'left'};gap:14px}
 .eyebrow{font-family:"Nunito Sans",Arial,sans-serif;font-weight:700;font-size:26px;letter-spacing:.22em;text-transform:uppercase;color:#F5B041}
 .name{font-family:"Bricolage Grotesque","Avenir Next","Helvetica Neue",Arial,sans-serif;font-weight:700;font-size:${variant==='square'?'128px':'112px'};letter-spacing:-.025em;line-height:.95;margin:4px 0 6px}
 .tag{font-family:"Bricolage Grotesque","Avenir Next","Helvetica Neue",Arial,sans-serif;font-weight:600;font-size:${variant==='square'?'46px':'40px'};letter-spacing:-.01em;color:#F2F4F7;opacity:.95}
 .sub{font-size:${variant==='square'?'27px':'24px'};color:#9AA5B5;max-width:${variant==='square'?'820px':'640px'};line-height:1.35;margin-top:6px}
 .foot{position:absolute;left:0;right:0;bottom:44px;display:flex;justify-content:center;gap:14px;align-items:center;font-size:22px;color:#9AA5B5;letter-spacing:.04em}
 .foot b{color:#F2F4F7;font-weight:700}
 .dot{width:6px;height:6px;border-radius:50%;background:#F5B041}
</style></head><body>
 <div class="glow"></div>
 <div class="wrap">
  <img class="icon" src="${icon}">
  <div class="text">
   <div class="eyebrow">Coming soon to iPhone</div>
   <div class="name">Lantern</div>
   <div class="tag">Ready for when you need it most.</div>
   <div class="sub">Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.</div>
  </div>
 </div>
 <div class="foot"><b>No account</b><span class="dot"></span><b>No cloud</b><span class="dot"></span><b>No subscription</b></div>
</body></html>`;
(async () => {
  const b = await chromium.launch();
  for (const [name, w, h, v] of [['lantern-coming-soon-square.png', 1080, 1080, 'square'], ['lantern-coming-soon-wide.png', 1200, 630, 'wide']]) {
    const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 2 });
    await p.setContent(page(w, h, v)); await p.waitForTimeout(1500);
    await p.screenshot({ path: name }); await p.close();
  }
  await b.close(); console.log('rendered');
})();
