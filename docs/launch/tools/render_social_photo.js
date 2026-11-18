// node render_social_photo.js
// Renders the photo-based Lantern images (site hero family, social posts, cover, story) at 2x from
// social_photo.html. The background photos in ../social/photo were generated with Runway Gen-4 Image
// (November 18, 2026); all lettering is set here so it stays sharp and accurate.
// This replaces render_social.js and ../../marketing/render-coming-soon.js for these files.
const { chromium } = require('playwright'); const path = require('path');
const jobs = [
 {
  "out": "../../marketing/lantern-coming-soon-wide.png",
  "w": 1200,
  "h": 630,
  "c": {
   "bg": "../social/photo/pantry-lantern-wide.jpg",
   "u": 0.857,
   "shade": "linear-gradient(90deg,rgba(16,20,31,0) 30%,rgba(16,20,31,.82) 47%,rgba(16,20,31,.95) 70%),linear-gradient(0deg,rgba(16,20,31,.55),rgba(16,20,31,0) 34%)",
   "box": {
    "left": "630px",
    "top": "0",
    "bottom": "0",
    "width": "530px"
   },
   "k": "COMING SOON TO IPHONE",
   "h1": "Lantern",
   "t": "Ready for when you need it most.",
   "s": "Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.",
   "chipsBottom": 32
  }
 },
 {
  "out": "../social/lantern-launch-wide-1200x630.png",
  "w": 1200,
  "h": 630,
  "c": {
   "bg": "../social/photo/pantry-lantern-wide.jpg",
   "u": 0.857,
   "shade": "linear-gradient(90deg,rgba(16,20,31,0) 30%,rgba(16,20,31,.82) 47%,rgba(16,20,31,.95) 70%),linear-gradient(0deg,rgba(16,20,31,.55),rgba(16,20,31,0) 34%)",
   "box": {
    "left": "630px",
    "top": "0",
    "bottom": "0",
    "width": "530px"
   },
   "k": "NOW ON THE APP STORE",
   "h1": "Lantern",
   "t": "Ready for when you need it most.",
   "s": "Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.",
   "badge": true,
   "chipsBottom": 32
  }
 },
 {
  "out": "../../marketing/lantern-coming-soon-square.png",
  "w": 1080,
  "h": 1080,
  "c": {
   "bg": "../social/photo/pantry-lantern-wide.jpg",
   "size": "auto 100%",
   "pos": "-310px 50%",
   "u": 0.86,
   "shade": "linear-gradient(90deg,rgba(16,20,31,0) 34%,rgba(16,20,31,.86) 50%,rgba(16,20,31,.96) 72%),linear-gradient(0deg,rgba(16,20,31,.7),rgba(16,20,31,0) 30%)",
   "box": {
    "left": "555px",
    "top": "0",
    "bottom": "60px",
    "width": "480px"
   },
   "k": "COMING SOON TO IPHONE",
   "h1": "Lantern",
   "t": "Ready for when you need it most.",
   "s": "Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.",
   "chipsBottom": 54
  }
 },
 {
  "out": "../social/lantern-launch-square-1080x1080.png",
  "w": 1080,
  "h": 1080,
  "c": {
   "bg": "../social/photo/pantry-lantern-wide.jpg",
   "size": "auto 100%",
   "pos": "-310px 50%",
   "u": 0.86,
   "shade": "linear-gradient(90deg,rgba(16,20,31,0) 34%,rgba(16,20,31,.86) 50%,rgba(16,20,31,.96) 72%),linear-gradient(0deg,rgba(16,20,31,.7),rgba(16,20,31,0) 30%)",
   "box": {
    "left": "555px",
    "top": "0",
    "bottom": "60px",
    "width": "480px"
   },
   "k": "NOW ON THE APP STORE",
   "h1": "Lantern",
   "t": "Ready for when you need it most.",
   "s": "Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.",
   "badge": true,
   "chipsBottom": 54
  }
 },
 {
  "out": "../social/lantern-launch-story-1080x1920.png",
  "w": 1080,
  "h": 1920,
  "c": {
   "bg": "../social/photo/pantry-lantern-tall.jpg",
   "pos": "50% 50%",
   "u": 1.6,
   "shade": "linear-gradient(180deg,rgba(16,20,31,.72) 0%,rgba(16,20,31,.5) 34%,rgba(16,20,31,0) 48%),linear-gradient(0deg,rgba(16,20,31,.8) 0%,rgba(16,20,31,.55) 16%,rgba(16,20,31,0) 26%)",
   "box": {
    "left": "80px",
    "right": "80px",
    "top": "235px",
    "height": "620px"
   },
   "align": "center",
   "k": "NOW ON THE APP STORE",
   "h1": "Lantern",
   "t": "Ready for when you need it most.",
   "s": "Most houses already have a week of food. Nobody has the list.",
   "badge": true,
   "chipsBottom": 330
  }
 },
 {
  "out": "../social/lantern-facebook-cover-1640x924.png",
  "w": 1640,
  "h": 924,
  "c": {
   "bg": "../social/photo/pantry-lantern-wide.jpg",
   "u": 1.12,
   "shade": "linear-gradient(90deg,rgba(16,20,31,0) 30%,rgba(16,20,31,.82) 47%,rgba(16,20,31,.95) 70%),linear-gradient(0deg,rgba(16,20,31,.55),rgba(16,20,31,0) 34%)",
   "box": {
    "left": "860px",
    "top": "0",
    "bottom": "0",
    "width": "700px"
   },
   "k": "LANTERN \u00b7 FOR IPHONE",
   "h1": "Ready for when<br>you need it most.",
   "hs": 0.5,
   "s": "Know what you have, where it is, and how long it's good. Food, water, medicine and gear, for the people you love.",
   "badge": true,
   "chips": false
  }
 },
 {
  "out": "../social/lantern-reddit-A1-1200x628.png",
  "w": 1200,
  "h": 628,
  "c": {
   "bg": "../social/photo/pantry-lantern-wide.jpg",
   "u": 0.857,
   "shade": "linear-gradient(90deg,rgba(16,20,31,0) 30%,rgba(16,20,31,.82) 47%,rgba(16,20,31,.95) 70%),linear-gradient(0deg,rgba(16,20,31,.55),rgba(16,20,31,0) 34%)",
   "box": {
    "left": "630px",
    "top": "0",
    "bottom": "0",
    "width": "540px"
   },
   "brand": true,
   "h1": "Food for 9 days. Water for 6.<br>Maria's pills run out Thursday.",
   "hs": 0.36,
   "s": "Scan the pantry, add who lives with you, and see how many days you are actually covered. The toolkit is free for everyone.",
   "badge": true,
   "chips": false
  }
 }
];
(async () => { const b = await chromium.launch();
  for (const j of jobs) { const p = await b.newPage({ viewport: { width: j.w, height: j.h }, deviceScaleFactor: 2 });
    j.c.w = j.w; j.c.h = j.h;
    await p.goto('file://' + path.join(__dirname, 'social_photo.html') + '#' + encodeURIComponent(JSON.stringify(j.c)));
    await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(600);
    await p.evaluate(() => Promise.all([...document.images].map(i => i.decode ? i.decode().catch(() => {}) : 0)));
    await p.screenshot({ path: path.join(__dirname, j.out) }); await p.close(); console.log(j.out); }
  await b.close(); })();
