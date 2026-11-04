// Renders every launch image from one template family. Run from this folder:
//   node render_social.js
// Needs the pre-installed Playwright. Fonts load from Google Fonts; the brand type is Bricolage Grotesque
// (display) and Nunito Sans (body). Amber is light only: the glow, the eyebrow, the dots. Never a button.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const SITE = path.resolve(__dirname, '../../../../kismetstudio-site/lantern');
const OUT = path.resolve(__dirname, '../social');
const icon = 'data:image/png;base64,' + fs.readFileSync(path.join(SITE, 'icon-512.png')).toString('base64');
const badge = 'data:image/svg+xml;base64,' + fs.readFileSync(path.join(OUT, 'appstore-badge-black.svg')).toString('base64');
const shot = (name) => 'data:image/jpeg;base64,' + fs.readFileSync(path.resolve(__dirname, '../press', name)).toString('base64');

const HEAD = `<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,700&family=Nunito+Sans:opsz,wght@6..12,500;6..12,700&display=swap">
<style>
 body{margin:0;background:#141B2B;color:#F2F4F7;font-family:"Nunito Sans","Helvetica Neue",Arial,sans-serif;overflow:hidden;position:relative}
 .glow{position:absolute;border-radius:50%;background:radial-gradient(circle,rgba(245,176,65,.30) 0%,rgba(245,176,65,.08) 45%,rgba(245,176,65,0) 70%)}
 .eyebrow{font-weight:700;letter-spacing:.22em;text-transform:uppercase;color:#F5B041}
 .name{font-family:"Bricolage Grotesque","Avenir Next",Arial,sans-serif;font-weight:700;letter-spacing:-.025em;line-height:.95}
 .tag{font-family:"Bricolage Grotesque","Avenir Next",Arial,sans-serif;font-weight:600;letter-spacing:-.01em;color:#F2F4F7;opacity:.95}
 .sub{color:#9AA5B5;line-height:1.35}
 .foot{position:absolute;left:0;right:0;display:flex;justify-content:center;gap:14px;align-items:center;color:#9AA5B5;letter-spacing:.04em}
 .foot b{color:#F2F4F7;font-weight:700}
 .dot{width:6px;height:6px;border-radius:50%;background:#F5B041}
 .icon{border-radius:22.37%;box-shadow:0 30px 80px rgba(0,0,0,.45);flex:none}
 .phone{border-radius:38px;box-shadow:0 40px 90px rgba(0,0,0,.55);border:6px solid #1C2436}
</style>`;

const FOOT = (size, bottom) => `<div class="foot" style="bottom:${bottom}px;font-size:${size}px"><b>No account</b><span class="dot"></span><b>No cloud</b><span class="dot"></span><b>Toolkit free for everyone</b></div>`;

const pages = {
  // Facebook post image, 1200x630: icon left, words right, badge.
  'lantern-launch-wide-1200x630.png': [1200, 630, `${HEAD}
  <div class="glow" style="left:50%;top:50%;width:760px;height:760px;transform:translate(-50%,-50%)"></div>
  <div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;gap:64px;padding:72px;box-sizing:border-box">
   <img class="icon" src="${icon}" style="width:300px;height:300px">
   <div style="display:flex;flex-direction:column;gap:14px;max-width:640px">
    <div class="eyebrow" style="font-size:24px">Now on the App Store</div>
    <div class="name" style="font-size:112px">Lantern</div>
    <div class="tag" style="font-size:38px">Ready for when you need it most.</div>
    <div class="sub" style="font-size:23px;max-width:600px">Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.</div>
    <img src="${badge}" style="width:180px;margin-top:10px">
   </div>
  </div>
  ${FOOT(22, 40)}`],

  // Instagram feed, 1080x1080.
  'lantern-launch-square-1080x1080.png': [1080, 1080, `${HEAD}
  <div class="glow" style="left:50%;top:38%;width:900px;height:900px;transform:translate(-50%,-50%)"></div>
  <div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:26px;padding:72px;box-sizing:border-box;text-align:center">
   <img class="icon" src="${icon}" style="width:340px;height:340px">
   <div class="eyebrow" style="font-size:26px">Now on the App Store</div>
   <div class="name" style="font-size:124px;margin:4px 0 6px">Lantern</div>
   <div class="tag" style="font-size:44px">Ready for when you need it most.</div>
   <div class="sub" style="font-size:26px;max-width:820px">Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.</div>
  </div>
  ${FOOT(22, 44)}`],

  // Story, 1080x1920: phone screenshot under the words.
  'lantern-launch-story-1080x1920.png': [1080, 1920, `${HEAD}
  <div class="glow" style="left:50%;top:30%;width:1100px;height:1100px;transform:translate(-50%,-50%)"></div>
  <div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;padding:150px 72px 0;box-sizing:border-box;text-align:center;gap:18px">
   <img class="icon" src="${icon}" style="width:200px;height:200px">
   <div class="eyebrow" style="font-size:26px;margin-top:10px">Now on the App Store</div>
   <div class="name" style="font-size:132px">Lantern</div>
   <div class="tag" style="font-size:42px;max-width:820px">Most houses already have a week of food. Nobody has the list.</div>
   <div class="foot" style="position:static;font-size:24px;margin-top:6px"><b>No account</b><span class="dot"></span><b>No cloud</b><span class="dot"></span><b>Toolkit free for everyone</b></div>
   <img class="phone" src="${shot('01-home.jpg')}" style="width:560px;margin-top:36px">
  </div>`],

  // Reddit ad creative A1, 1200x628: the headline is the ad; the image carries the phone and the promise.
  'lantern-reddit-A1-1200x628.png': [1200, 628, `${HEAD}
  <div class="glow" style="left:30%;top:50%;width:800px;height:800px;transform:translate(-50%,-50%)"></div>
  <div style="position:absolute;inset:0;display:flex;align-items:center;gap:56px;padding:56px 72px;box-sizing:border-box">
   <div style="display:flex;flex-direction:column;gap:16px;flex:1">
    <div style="display:flex;align-items:center;gap:18px"><img class="icon" src="${icon}" style="width:84px;height:84px;box-shadow:none"><div class="name" style="font-size:56px">Lantern</div></div>
    <div class="tag" style="font-size:46px;line-height:1.05;max-width:640px">Food for 9 days. Water for 6. Maria's pills run out Thursday.</div>
    <div class="sub" style="font-size:23px;max-width:600px">Scan the pantry, add who lives with you, and see how many days you are actually covered for. The toolkit is free for everyone.</div>
    <img src="${badge}" style="width:170px;margin-top:4px">
   </div>
   <img class="phone" src="${shot('05-ready.jpg')}" style="width:300px;flex:none">
  </div>`],

  // Facebook cover, 1640x924. Words inside the desktop-safe band (y 150 to 774); lower left left clear for the profile picture.
  'lantern-facebook-cover-1640x924.png': [1640, 924, `${HEAD}
  <div class="glow" style="left:72%;top:50%;width:1000px;height:1000px;transform:translate(-50%,-50%)"></div>
  <div style="position:absolute;left:520px;top:190px;width:640px;display:flex;flex-direction:column;gap:16px">
   <div class="eyebrow" style="font-size:22px">Lantern · for iPhone</div>
   <div class="name" style="font-size:88px">Ready for when you need it most.</div>
   <div class="sub" style="font-size:24px;max-width:600px">Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.</div>
   <img src="${badge}" style="width:170px;margin-top:6px">
  </div>
  <img class="phone" src="${shot('03-outage.jpg')}" style="position:absolute;right:120px;top:120px;width:300px">`],
};

(async () => {
  const b = await chromium.launch();
  for (const [name, [w, h, html]] of Object.entries(pages)) {
    const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 2 });
    await p.setContent(`<html><head>${html.split('<div')[0]}</head><body>${html.slice(html.indexOf('<div'))}</body></html>`);
    await p.waitForTimeout(1800);
    await p.screenshot({ path: path.join(OUT, name) });
    await p.close();
    console.log('rendered', name);
  }
  await b.close();
})();
