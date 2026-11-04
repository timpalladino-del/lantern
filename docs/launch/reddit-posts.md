# Reddit posts, ready to paste

Titles and bodies are separate because Reddit asks for them separately. Direct links are allowed only in
the builder subs (r/SideProject, r/iosapps, r/AppHookup, r/iOSProgramming). Everywhere else: text only,
link in a comment only when someone asks. Read each sub's sidebar before posting. Post from the account you
already use, never a fresh one. Reply to every comment for two hours after posting.

Words that never appear in any of these: prepper, survival, bug out, SHTF, tactical, threat, doomsday,
free, buy, any price, your employer.

---

## Post 1 · r/SideProject · Day 1 (link allowed)

**Title:** I built the app I wished we'd had the night the power went out. It's on the App Store today.

Two winters ago we lost power for four days. We had, it turned out, about a week of food in the house. I
could not have told you that at the time, or where it was, or how old any of it was. We ate the freezer in
the wrong order, threw out things that were fine, and ran out of the one thing that mattered, which was my
wife's blood pressure medication.

So I spent this year building Lantern. It is a household readiness app for iPhone. Not a bunker app. It is
for the ordinary version of being ready: a full pantry, water that gets rotated, medicine that has not
expired, and a plan everyone in the house knows.

What it actually does:

- Scan a barcode or a printed date and the item is logged. It knows the shelf life of about ninety staples,
  so a can with no date still gets one. The barcode lookup also pulls the nutrition panel in.
- Add who lives in the house (ages, sizes, medications, pets) and it turns the pantry into days of food
  and water for those actual people. Real calories, real gallons, not a score out of 100.
- Every person has a medication card: dose, times, take with food, who prescribed it. One card for the
  whole house that you can text to a neighbour or print for the fridge.
- Family members fill in their own profile from a link. No account, no server. The link is the transport.
- Outage mode starts the clocks on the fridge and freezer and gives you the generator and carbon monoxide
  cards. There is an SOS strobe, a whistle, a compass, the NOAA radio frequencies.

The toolkit half is free for everyone with no sign-up. The tracking half is free for one person and fifty
items, and there is a yearly Family plan for a whole house.

Tech, since this is r/SideProject: SwiftUI and SwiftData, iOS 18, no backend at all. Barcodes go to Open
Food Facts and nothing else leaves the phone. StoreKit 2 for the plans. The hardest parts were the
shelf-life library (hand-built from USDA, CDC and FDA sources, every entry cites one) and the calorie math,
which uses Mifflin-St Jeor when it knows a person's weight and height and the Dietary Guidelines bands
when it does not.

Honest numbers so far: nine beta testers, all family and friends, two weeks of TestFlight. Downloads: it
went live this morning, so none yet. I will post the first month's numbers here either way.

App Store: https://apps.apple.com/us/app/id6830418364

Happy to answer anything about the build or the choices.

---

## Post 2 · r/iosapps · Day 2 (link allowed)

**Title:** Lantern: a calm household readiness app. Scan your pantry, see how many days your family is covered, medication cards, outage mode. No account.

Shipped yesterday after a year of evenings.

The short version: most households already own a week of food, a case of water and a drawer of batteries.
What they do not have is a list. Lantern keeps it, and turns it into something you can act on: "food for
9 days, water for 6, Maria's lisinopril runs out in 11."

- Barcode and printed-date scanning, on device
- Shelf-life library for ninety-plus staples with sources
- Readiness in days for your actual people and pets
- Medication cards you can hand to anyone
- Family profiles by link, no server
- Outage mode: fridge and freezer clocks, generator and CO cards, check-in reminder
- SOS strobe, whistle, compass, NOAA frequencies, know-how cards from CDC, FEMA and the Red Cross
- No account, no cloud, no analytics. Everything stays on the phone.

The toolkit is free for everyone. iPhone, iOS 18 and up.

https://apps.apple.com/us/app/id6830418364

If the first screen does not make sense in five seconds, tell me what you expected instead.

---

## Post 3 · r/iOSProgramming · Day 3 (link allowed, keep it technical)

**Title:** What I learned shipping a local-first SwiftData app with StoreKit 2 subscriptions and no backend

Lantern went live this week. A few things that cost me time, in case they save you some:

1. **SwiftData synchronized folders are great until you put Info.plist in one.** "Multiple commands
   produce" with no useful path. Move it to a Config folder outside the synchronized group.
2. **Universal links for a no-server app.** The family profile link is `https://kismetstudio.io/lantern/p/import?d=...`
   with the whole profile base64url-encoded in the query. The AASA file on GitHub Pages needs a `.nojekyll`
   so Pages serves `.well-known`. The fallback page redirects to a custom scheme for people who have the app
   but somehow did not get the universal link.
3. **StoreKit 2 subscriptions need prices in every territory before App Review will take them.** "Missing
   metadata" with no further detail means one of 175 territories has no price. The equalizations endpoint
   fills them all from the base price.
4. **The App Store Connect API can do almost everything except create the app record and publish the
   privacy label.** Those two are web only. Everything else (screenshots, metadata, age rating, review
   contact, subscription prices, intro offers, attaching a build, submitting) scripted fine with an ES256
   JWT and urllib.
5. **Apple rejects screenshots with prices in them** (2.3.7). Learned on a previous app; checking again on
   this one.
6. **Testing a bottom toolbar inside a TabView on a real phone.** On iOS 26 the floating tab bar hid a
   `.bottomBar` toolbar in edit mode. A `safeAreaInset(edge: .bottom)` bar is what actually shows.

Stack: SwiftUI, SwiftData, StoreKit 2, VisionKit DataScanner for barcodes and dates, UserNotifications for
the outage check-in and medication reminders. No third-party packages.

https://apps.apple.com/us/app/id6830418364

---

## Post 4 · r/homeowners · first Saturday after launch (no link, no app name in the body)

**Title:** The twenty-minute pantry audit that tells you how many days you could actually stay home

Every house I have been in has more food in it than the people living there think. The problem is nobody
knows what, or where, or how old. Here is the audit I do twice a year. Twenty minutes, no shopping.

1. **Pull everything shelf-stable onto the counter.** Cans, rice, pasta, oats, peanut butter, crackers,
   bars, the weird jar of beans from 2023. Pantry, basement, garage, car.
2. **Date it.** Printed date if there is one. If there is not: canned low-acid food (beans, soup, meat) is
   good for two to five years from purchase; high-acid (tomatoes, fruit) about eighteen months; white rice
   and dried pasta basically indefinitely if sealed and dry; peanut butter about a year; crackers and bars a
   few months. A dented, rusted or swollen can goes in the bin. Everything else past its date is a quality
   question, not a safety one.
3. **Count calories, roughly.** A can of beans or soup is about 350. A pound of rice or pasta about 1,600.
   A jar of peanut butter about 2,700. Add it up.
4. **Divide by the people.** An adult needs about 2,000 a day sitting around the house. A teenager more. A
   child of nine, about 1,700. So a family of four is roughly 7,500 a day.
5. **Do the same for water.** One gallon per person per day, plus a bit for pets. A case of 24 bottles is
   about three gallons. Count the gallons you have and divide.
6. **Then the medicine cabinet.** For each daily medication, count the pills and divide by the daily dose.
   That number of days is your real limit, and it is usually the shortest one in the house.

The Red Cross says three days if you might have to leave and two weeks if you are staying home. Most
houses I have audited are at six to ten days of food, three to five of water, and somewhere under a week
on at least one medication. Water is nearly always the gap, and it is the cheapest thing to fix.

Put the oldest stuff at the front and eat it this month. That is the whole trick. You are not stockpiling,
you are rotating.

*(If someone asks what you use to keep track: "I built an app for it, I'll put the link in a reply if
that's okay with the mods." Then the direct link, once.)*

---

## Post 5 · r/firsttimehomebuyer · Day 12 (no link)

**Title:** Things to find and photograph in your first week in the house, before you need them in the dark

You will need all of these at 2 a.m. one day. Find them now, while the lights are on, and take a photo of
each with your phone.

- **The main water shutoff.** Usually where the line enters the house, often near the water heater or in
  the basement front wall. Turn it a quarter turn to confirm it moves. A seized valve is a Saturday job
  now, a flood later.
- **The gas shutoff**, if you have gas. On the meter outside. You need a wrench to close it; put one next
  to it. You do not turn it back on yourself; the utility does.
- **The electrical panel.** Open it. Label anything unlabeled while you figure out what each breaker does.
  Photograph the labeled panel.
- **The water heater.** Model number, serial, age (date code on the label), and the type: tank or
  tankless, gas or electric. This decides half your maintenance.
- **The furnace or air handler filter size.** It is printed on the edge of the filter. Photograph it.
- **The smoke and CO detectors.** Each has a manufacture date on the back. Smoke alarms are replaced at ten
  years, CO alarms at seven to ten depending on the model. Half the houses I have been in have one past its
  date.
- **The fire extinguisher**, if there is one. Pressure gauge in the green, pin in, less than twelve years
  old. If there is not one, that is the first thing to buy.
- **Where the previous owner kept the manuals**, if they left any. Kitchen drawer, basement shelf, the
  top of the water heater.

Put all the photos in one album called House. Add the previous owner's generator, sump pump and well pump
if those exist. Then you have what every repair person, insurance adjuster and 2 a.m. emergency will ask
you for, and you got it in an hour with the lights on.

---

## Post 6 · r/Parenting · Day 8 (no link)

**Title:** The one card every babysitter, grandparent and school nurse should have for your kid

My son has asthma. The number of times the right information was in my head and not in anyone else's
hands is embarrassing. Here is the card I keep now, one per child, as a note on my phone and printed on
the fridge.

- Name, date of birth, weight (dosing goes by weight)
- Every medication: name, dose, when, and the plain-English version of how ("two puffs, shake it first,
  wait a minute between")
- The rescue medication and exactly when to use it
- Allergies, including the ones that seem minor
- Conditions in one line each
- Blood type if you know it
- Doctor's name and number, pharmacy name and number
- Two adults to call, in order
- Anything that helps when things are hard: the blanket, the song, the headphones

Keep a copy in the go-bag and in the car. Give one to anyone who ever has your kid for more than an
hour. Update it when a dose changes.

The thing nobody tells you is that in an actual emergency the card is for *you*. Your memory is the first
thing that goes.

---

## Post 7 · r/CaregiverSupport · Day 19 (no link, be a person first)

**Title:** How I stopped losing track of my mother's nine prescriptions (the system, not an ad)

Nine medications, four times of day, two that cannot be missed, one that has to be in the fridge. When
the power went out last winter the refrigerated one was the whole problem.

What works for us now:

1. One list, one place, that anyone in the family can see. Name, dose, times, with food or not, who
   prescribed it, pharmacy number, Rx number. The Rx number is the thing the pharmacy asks for first.
2. "Cannot miss a day" is marked on the list. Those two get counted every Sunday: pills in the bottle
   divided by pills per day equals days left. Under ten days, call for the refill.
3. The refrigerated one has a plan written next to it: cooler with ice packs holds 48 hours; unopened
   insulin is fine a month at room temperature. I did not know that until I looked it up in a panic.
4. The whole list is printed and in her go-bag, and texted to my brother, because the night something
   happens is not the night to be reading it out over the phone.

If anyone wants the template I use, I am happy to share it in a reply. Mods, if an app mention is not
okay here, I will keep it to the template.

---

## Post 8 · r/AppHookup · Day 16 (link allowed; giveaway)

**Title:** [iOS] Lantern: Household Readiness. 25 one-year Family codes for the people who try it and tell me what is wrong.

Lantern keeps track of the food, water, medicine and gear you keep for a bad week, and turns it into days
of cover for your actual household. Medication cards, family profiles by link, outage mode with fridge and
freezer clocks, SOS strobe, NOAA frequencies. No account, no cloud.

The toolkit half is free for everyone. The tracking half is free for one person and fifty items; Family
covers a whole house for a year.

25 one-year Family codes below for the first 25 who want them. One per person. Redeem: download the app
first, then tap your picture in the App Store app, Redeem Gift Card or Code. Codes expire [DATE].

https://apps.apple.com/us/app/id6830418364

[CODES, one per line]

In return I would love one thing: tell me the first moment the app confused you.

---

## Post 9 · r/apple weekly self-promo thread · Day 5 (two lines, no pitch)

Lantern: Household Readiness. Scan your pantry, see how many days your family is covered, medication
cards, outage mode. No account, no cloud, iPhone. https://apps.apple.com/us/app/id6830418364

---

## Post 10 · r/florida · only while the flooding is in the news (no link, local first)

**Title:** Post-flood kitchen: what to keep, what to toss, and how to not do this again next time

From the FDA and USDA guidance, not opinion:

- Any food that touched floodwater goes. That includes cans and jars if the seal or the lid got wet
  and you cannot sanitize them. Commercially canned food that stayed sealed can be kept if you wash the
  can, remove the label, sanitize in a bleach solution and relabel with a marker. Most people do not.
- Fridge: four hours without power and the perishables are done. Freezer: 48 hours full, 24 half full,
  if the door stayed shut. When in doubt, throw it out.
- Tap water: wait for the boil notice to lift. Bottled until then.

For next time, the thing that actually helps is a list of what you have before the storm: the cans, the
water, the medications and when each runs out. Write it down this week while the shelves are empty and
you are restocking anyway. One gallon of water per person per day, two weeks if you are staying. The
medication count is the one most people get wrong.

Stay safe. 211 has the shelter list if you need it.

---

## Message to mods before any AMA (r/HomeMaintenance or r/CaregiverSupport, Day 18)

Hi, I built an iPhone app for household emergency supplies (pantry, water, medication tracking) and I am
not asking to promote it. I would like to run a "ask me your expiration date / shelf life question"
thread with answers from the USDA and FDA tables I built the app from, with no link and no app name in
the post. If that is welcome, what day works and is there anything you would like me to avoid? Thank you.

---

## Daily (all home, parenting and caregiver subs)

Three helpful comments a day with no mention of the app. Shelf-life questions, "how much water", "my
smoke alarm is chirping", medication storage in a heat wave. This is the account the launch posts ride on.
Nine helpful contributions for every one app mention.
