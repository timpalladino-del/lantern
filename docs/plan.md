# Household Preparedness App: Research and Product Plan

Working title: none yet (branding deferred). Referred to below as "the app."
Date: November 2, 2026. Research sources are listed at the end.

---

## 1. The idea in one paragraph

A calm, mainstream "stay-ready" app for ordinary households: one place for the food, water, medicine, gear, documents and plans a family keeps for outages, storms, illness and other bad weeks. It borrows the CastleWise model (local-first, no account, one-time price, a hand-built reference library, camera assist) but not its branding. The positioning line the target audience already uses for itself: **"Prep for Tuesday, not doomsday."**

## 2. Who it is for

**Primary:** households that have started buying extra supplies after a storm, outage, or news cycle, and now have stuff in three closets and no idea what is expiring. Research shows this group skews female, millennial and Gen Z, often renters or apartment dwellers, and actively avoids the word "prepper."

- r/TwoXPreppers split from r/preppers in 2022 and is now one of the most active preparedness communities. Its framing: "practical self-care," "insurance," "your doomsday is our Tuesday."
- Finder survey: roughly 40% of Gen Z and 39% of millennials spent money on preparedness in the past year, versus 29% of adults overall.
- SafeHome 2026 survey: only 5% of US homes have a fully stocked kit, 20% have nothing, and cost is the most-cited barrier.
- Government normalization: the EU's 72-hour household self-sufficiency target (2025), the UK "Be Ready" campaign, FEMA's September National Preparedness Month.

**What turns them off:** bunkers, guns, MRE culture, "survive" and "mission" language, doomsday framing, expensive gear, being called paranoid by family. Every prepper-branded app on the App Store today fails this test by name alone.

**Secondary:** experienced preppers who currently run spreadsheets. They will tolerate a mainstream tone if the inventory engine is strong, and they are the loudest reviewers.

## 3. What the research says people struggle with

Ranked by how often it recurred across forums, reviews and press.

1. **Spreadsheets get built, then abandoned.** "Never found time to update it." Vendor estimate: most stop within weeks.
2. **Manual entry kills apps too.** An app that makes you type every item and date "has the same abandonment problem as a spreadsheet." Grocy is praised for scope and abandoned for data entry.
3. **No payoff at the moment of updating.** Logging a used can gives nothing back, so nobody logs it.
4. **Expired and forgotten stock.** A UK prepper opened tins six years past date. The community rule is "only stock what you eat routinely," which requires rotation.
5. **Rotation is "never ending."** People try barcode in/out systems in Excel and give up.
6. **Supplies scattered across locations, duplicates bought.** "If you can't walk to an item from its record, the inventory isn't useful."
7. **Must work with no power and no internet.** "Excel is no good if the power goes out." Several keep a printed binder. Preppr's top review complaint: inventory needs internet.
8. **Beginner overwhelm.** "Totally overwhelmed, frustrated, and underprepared." Advice given: start with low-hanging fruit, think about your actual likely scenarios.
9. **Budget barrier.** Cost is the top reason people have no kit.
10. **Water rotation uncertainty.** Advice ranges from 6 months to 3 years. People put painter's tape with a fill date on the lid.
11. **Medication and first-aid dates.** No tracking method exists beyond "write the purchase date on it."
12. **Forgotten equipment upkeep.** Generator exercise runs, extinguisher gauges, alarm tests, power-station top-ups. Nobody tracks these in a preparedness context.
13. **Unsupportive partner.** Recurring thread topic. A shared, non-weird app is a way to bring a spouse in.
14. **Prepper fatigue and anxiety.** People burn out on worry. Tone matters: the app should reduce anxiety, not feed it.
15. **Go-bag upkeep.** Kids outgrow clothes in the bag, batteries die. The one go-bag app only tracks one bag.

## 4. Competitor gaps

| Gap | Evidence |
|---|---|
| Nobody combines food + water + gear + documents + plans | Pantry apps ignore gear. FEMA and Red Cross apps have checklists but no quantities or expiry. Home-inventory apps ignore consumables. Only Grocy spans food and equipment, and it is self-hosted and "ludicrously complex." |
| No mainstream tone | Every prepper app is named Prepper, Preppr, PrepperPro, Survival Plan. Pantry apps are framed around food waste, not readiness. |
| Local-first is demanded but poorly delivered | PrepperPro wiped inventories on low bandwidth. Preppr needs internet. The offline apps that exist are unpolished Android or web tools. |
| Equipment maintenance reminders do not exist in this category | Generator apps are standalone. Forum users use calendar reminders. |
| Shelf-life knowledge is thin | Barcode lookups give packaged dates only. Nobody ships curated data for water, fuel, batteries, meds, opened versus sealed, or deep storage. |
| Family sharing is the number one reliability complaint | Pantry Check, NoWaste, KitchenPal and Nest Egg all have sync-broke reviews. A working CloudKit share is a differentiator on its own. |
| Abandonment risk | Prep & Pantry last updated 2021. Thrive Life closed 2025. Users want CSV export as insurance. |
| Readiness score / days of supply | Exists only in small Android and web tools. No quality iOS version. |

**Pricing norms:** pantry apps charge $7 to $15 per year or $30 lifetime. One-time micro-prices ($2 to $7) are common and praised. Subscription resentment spikes above $4 per month. Nest Egg's one-time purchase is explicitly praised in reviews. A one-time $9.99 to $14.99 fits the category and avoids its loudest complaint.

## 5. Product principles

1. **Capture in under five seconds.** Barcode, date scan, or one tap on a starter pack. Typing is the fallback, never the default.
2. **Every update pays off immediately.** Marking a can used adds it to the shopping list, updates days-of-supply, and clears an alert. Make the app answer "what should I use this week?" so opening it is useful even when nothing is wrong.
3. **Works in the dark.** Everything on-device. Outage Mode is available with no signal. Printable PDF of the inventory for the binder people.
4. **Calm, not alarming.** Readiness is shown as progress, not a fear score. Copy is practical. No countdowns, no red everywhere.
5. **Honest about dates.** "Best if used by" is quality, not safety, except infant formula. The app explains this instead of screaming "EXPIRED" over a can of beans.
6. **A library, not a guess.** Shelf life, maintenance intervals and checklists come from USDA, CDC, FEMA, NFPA and manufacturer sources, cited in-app. Apple reviewers reject health and safety content with no sources.
7. **No account, no cloud by default, one-time price.** Household sharing via iCloud is the one optional sync, and it is Apple's infrastructure, not ours.
8. **Start small on purpose.** Onboarding asks three questions and produces a short first list, not a 60-item kit.

## 6. Feature plan by phase

### Phase 1: MVP. Solves the user's own problem today.

**Supplies inventory**
- Item record: name, quantity, unit, location, purchase date, expiration or best-by date, "opened" toggle, notes, photo.
- Categories: food, water, medicine and first aid, hygiene, power and light, tools and gear, pet, baby, documents, cash, other.
- Locations are first-class: Pantry, Basement shelf, Car, Go-bag, Office. Multiple containers per location. "Walk to it" test passes.
- Barcode scan via Apple VisionKit, on-device. Product name and image from Open Food Facts (with required attribution), falling back to a local "my products" memory so the second scan of the same item is instant.
- Date scan: point camera at the printed date, OCR on-device, confirm with one tap.
- Shelf-life auto-estimate when no date is printed: USDA FoodKeeper data (public domain, bundled) plus a curated deep-storage table (rice, beans, oats, pasta, honey, salt, sugar, powdered milk, freeze-dried, MREs, canned high-acid versus low-acid).
- Opened versus sealed changes the estimate (oil, peanut butter, flour, powdered milk).
- Quick quantity controls: swipe to use one, long-press to adjust. Bulk "I just did a Costco run" multi-scan mode.

**Expiration alerts and rotation**
- Alert ladder per item class: 60/30/7 days for food, 6 months before for deep storage, custom for meds.
- Weekly "Use this week" digest: a short list of what to cook or swap out, with a one-tap "used it, add to shopping list."
- Rotation queue sorted by date across all categories and locations.
- Snooze, "I checked it, still fine" (extends by a sensible interval for canned goods), and "tossed it."
- Water containers track a fill date, with a 6-month rotation reminder per CDC guidance. Digital version of the tape-on-the-lid trick.

**Equipment with notes and maintenance**
- Equipment record: model, serial, purchase date, fuel type, battery type and count, manual photo, notes, where it is.
- Maintenance schedules from a built-in table, editable: generator exercise run monthly and oil at 100 hours or yearly; fire extinguisher visual check monthly, replace at 12 years; smoke and CO alarms test monthly, battery yearly, replace at 10 years; power station top-up every 3 months; first-aid kit review every 6 months; propane cylinder requalification at 12 years; stored gasoline rotate yearly; sump pump test quarterly; water filter replacement per manufacturer.
- Log entries: "Ran generator 20 min, 11/2/26." The log is the notes history the user asked for.
- Battery tracker: what sizes each device needs versus how many spares you have, with shelf life (alkaline up to 10 years, lithium up to 20).

**Readiness view**
- Household setup: people, pets, dietary notes, location (state or region only, never GPS).
- Days of supply for food, water, and medicine based on household size and Red Cross targets (3 days to evacuate, 2 weeks at home).
- Gap list: what you would need to reach your chosen target, with estimated cost, generated as a shopping list. This is the "payoff" for keeping inventory current.

**Export and trust**
- CSV and PDF export, free, always. Printable binder sheet.
- Full local backup file. Restore from file.

### Phase 2: What makes it a household tool

- **Kits and bags as containers.** Go-bag per person, car kit, office kit, pet kit. Checklist templates from Ready.gov and Red Cross, with "last reviewed" dates and a 6-month review reminder. Kids' kits flag outgrown clothing and seasonal swaps.
- **Household sharing** via CloudKit shared zones. Partner scans a can at the store, it appears on your phone. Build this carefully and test sync failures, because broken sharing is the number one review complaint in the category.
- **Shopping list integration.** Everything consumed or missing flows to one list, grouped by store. Optional Reminders app export.
- **Seasonal readiness checklists.** Hurricane (June to November), wildfire (summer to fall), winter storm, tornado season, heat, earthquake. Shown by the user's region and the calendar. Each is a short "before the season" list mapped to inventory and equipment, so "check generator" is a tap, not a sentence.
- **Documents vault.** FEMA Emergency Financial First Aid Kit checklist: IDs, insurance, deed or lease, medical list, contacts, account list. Photos stored encrypted on-device behind Face ID. Insurance home-inventory walkthrough (room photos plus serials) since 46% of homeowners have none.
- **Medication tracker.** Household meds with quantity and date, 7-day supply target from Red Cross, refill reminders. Neutral on expired meds: shows FDA's position and does not advise use.

### Phase 3: Intelligence and the moment of need

- **Outage Mode.** One big button when the power goes out. Starts the USDA fridge and freezer clock (4 hours fridge, 48 hours full freezer, 24 half-full), shows your flashlight and battery inventory, surfaces the generator CO safety card (20 feet from the house, never in a garage), lists cash on hand and water stored, and works fully offline.
- **Camera check (the FixLens equivalent).** "What is this and is it still good?" for a bulging can, a rusty lid, a mystery MRE date code, a generator fault code, or a battery type. On-device library first, optional Claude-powered check second, clearly labeled, same privacy model as CastleWise.
- **Scenario planner.** "3-day outage, 4 people, winter." Shows what you have, what you lack, and a budgeted shopping list to close the gap at $20 a week. Directly addresses the cost barrier and the overwhelm problem.
- **Know-how library.** Short plain-language cards: water disinfection ratios (8 drops of unscented bleach per gallon, 30 minutes), what to do when the freezer thaws, how to store gasoline, how to test a sump pump. Each card cites its source.
- **Skills and drills.** Twice-yearly family drill reminder tied to daylight saving changes (meet point, where the shutoffs are, who grabs the pets). Light, optional, not gamified into anxiety.
- **Widgets and Siri.** "Hey Siri, we used a can of beans." Lock-screen widget showing items expiring this month.
- **Smart suggestions.** "You have 40 cans of beans and no can opener in the go-bag." Rule-based, from the library.

### Phase 1.5: Trusted contact (for people living alone) — built November 3, 2026
- Household has "Who checks on you?": one or two named contacts outside the house with phone numbers.
- One tap sends them the medication card and the plan as text.
- The outage check-in reminder names them ("Text Dana: where you are, that you're okay, your battery").
- Home prompts for it when the household has exactly one person and no trusted contact yet; the plan PDF lists them.

### Kits — built November 3, 2026
- `Kit` is a container (go-bag, car, pet, work, other). Items in a kit are ordinary supplies with a `kit` link,
  so they count toward readiness and get the same reminders. Deleting a kit keeps its items.
- Templates in `kits.json` (Ready.gov go-bag, car kit, pet bag). A kit started from a template shows what is
  still missing with one-tap add. "Pack something you already have" moves existing items in.
- "Checked" stamps the kit and its items; a kit not checked in six months shows in Ember.
- Free: one kit. More kits are part of Family.

### App icon for iOS 26 — built November 3, 2026
- `Lantern/AppIcon.icon` is an Icon Composer package: a navy fill with the lit disc and lantern as one layer,
  so iOS 26 derives the Clear and Tinted appearances itself. The asset-catalog AppIcon stays as the iOS 18 fallback.

### Pet food and the medication list — built November 4, 2026
- Pets carry cups of dry and cans of wet food a day (350 and 400 kcal), brand, and a prescription-diet flag;
  otherwise needs are estimated from weight (70 × kg^0.75 × 1.6 dogs / 1.2 cats). Pet-category items that read
  like food count toward it with label calories or typical values (1,600 kcal/lb dry, 400 per can). Ready shows
  a Pet food bar and the gap list suggests pounds to buy.
- `medications.json`: 190-plus common US medicines (generic, brands, strengths, purpose, form, label
  instructions, can't-miss flag). The medication form has "Find it in the list" plus inline suggestions as
  you type; search tolerates misspellings (edit distance) and matches brand or purpose.

### Universal links — built November 3, 2026
- Profile links are now `https://kismetstudio.io/lantern/p/new` and `/lantern/p/import`, served by the site with
  `/.well-known/apple-app-site-association` and the `applinks:kismetstudio.io` entitlement. Without the app the
  link lands on a page that explains and tries the `lantern://` scheme; the app still accepts both forms.

## 7. More ideas to consider (backlog)

- Receipt scan to batch-add a grocery run.
- "Eat down" recipe suggestions from items expiring soon (local, from a small recipe set).
- Rotation nudge on your grocery day: "Take 2 cans of tomatoes from deep storage to the kitchen, buy 2 to replace."
- Freezer and fridge inventory with power-outage safety logic built in.
- Vehicle kit with seasonal swap list and "keep tank half full in winter" reminder.
- Neighbor and family contact card that works offline, printable.
- Pet profile: food days, meds, vet records, current photo for lost-pet flyers.
- Budget tracker: what you spent on readiness this year, and what it would cost to replace.
- Insurance claim helper: export photos and serials in the format adjusters ask for.
- "Borrowed and lent" for shared generators, chainsaws, coolers.
- Expiration date for cash? No. But a reminder to keep small bills, and a count.
- Community templates: share a kit template as a file, no server needed.
- Apple Watch: tick off a kit check while standing in the garage.
- Printable QR labels for totes that open the tote's inventory.
- Fuel log: gallons stored, stabilizer added date, rotate-by date.
- Chest freezer map (grid like the CastleWise panel map): what is in which basket.

## 8. Expiration and alert design, in detail

Since this is the problem the user is hitting right now, the rules the app should follow:

**Date source priority**
1. Printed date on the package, scanned or typed.
2. FoodKeeper estimate from purchase date (pantry, opened or unopened).
3. Deep-storage table if the item is flagged as long-term storage (cool, dry, oxygen-free assumption shown).
4. Category default, clearly marked as a guess.

**Language**
- Food: "Best by" and "Use first," not "Expired," unless the item is infant formula, medicine, or a user-set hard date.
- Canned goods past date and intact: "Past best-by date. Safe if the can is not rusted, dented or swollen." Offer "Checked, still fine" and "Toss."
- Medicine: show the date and FDA guidance, never a "still fine" button.

**Alert cadence**
- One weekly digest by default. Per-item pings only for medicine, water rotation and equipment tasks. People already have alert fatigue.
- Reminders scheduled by iOS locally, no server, so they fire during an outage too.

**Capture flows ranked by speed**
1. Rescan a known barcode: 1 tap, quantity +1.
2. Starter pack ("Costco emergency bucket," "Red Cross 3-day kit"): 1 tap adds all lines.
3. New barcode: scan, confirm name, scan date, done.
4. No barcode (bulk rice, home-canned): type name, pick category, FoodKeeper fills the rest.

## 9. Content library to build (the moat)

All of this ships inside the app, offline, with citations.

| Content | Source | License status |
|---|---|---|
| Everyday shelf life, ~650 foods | USDA FoodKeeper JSON (data.gov) | CC0, bundle freely |
| Deep-storage shelf life | LDS Home Storage, BYU 30-year studies, university extensions | Paraphrase and cite, do not copy tables |
| Power-outage food safety | USDA FSIS | Public domain |
| Water storage and disinfection | CDC | Public domain |
| Kit checklists | Ready.gov, FEMA | Public domain. Re-verify wording; Ready.gov shows an "under revision" banner. |
| Red Cross kit targets | Red Cross | Paraphrase and cite |
| Document checklist | FEMA EFFAK (P-2063) | Public domain |
| Alarm and extinguisher intervals | NFPA via state fire marshal pages, USFA | Cite fire-marshal pages, NFPA standards are paywalled |
| Generator intervals and CO safety | CPSC, Generac and Honda manuals | Cite manufacturer |
| Battery, power station, filter life | Manufacturer pages | Cite manufacturer |
| Seasonal hazard calendars | NWS, NHC, CAL FIRE Ready Set Go | Public domain, cite |
| Medication expiration context | FDA SLEP studies (Lyon 2006, Cantrell 2012) | Cite, present neutrally |

## 10. Technical plan

- **Platform:** iOS 17+, SwiftUI, SwiftData (or Core Data if CloudKit sharing is needed in Phase 2, since shared zones are easier there). iPhone first, iPad layout later.
- **Scanning:** VisionKit DataScannerViewController for barcode and text in one view. Custom date parser for "BEST BY 03/27," "EXP 2027-03," "BB 27MAR," Julian codes where known.
- **Product lookup:** Open Food Facts API with a proper User-Agent. ODbL: attribution on screens where their data appears and in the store listing. Do not mix OFF data into a redistributed database. Cache per-device only. Fallback: user-named products stored locally and reused.
- **Shelf life:** FoodKeeper JSON bundled and indexed at build time. Deep-storage table hand-written as JSON with source fields.
- **Notifications:** UNUserNotificationCenter local scheduling. Weekly digest plus per-item exceptions.
- **Storage and privacy:** on-device only. Documents vault encrypted with a key in the Secure Enclave, Face ID gated. No analytics SDK; anonymous counts only, opt-out, as in CastleWise.
- **Sharing (Phase 2):** CloudKit shared record zones. Design for conflict resolution and offline queues from day one. Test the "partner's phone is in airplane mode for a week" case.
- **Export:** CSV, PDF (binder sheet), JSON backup. All free.
- **Camera check (Phase 3):** reuse the CastleWise Expert Check server pattern (anonymous per-install ID, rate limit, nothing stored).
- **App Store:** cite sources in-app for health and safety content (Guideline 1.4.1). Add "not a substitute for 911 or medical advice" and "check with a doctor" where medicine appears. Avoid a checklist-only build (Guideline 4.2.2 rejects content aggregators), which the inventory engine satisfies.

## 11. Pricing and household size

Decided November 3, 2026, after several passes the same day (earlier drafts are in git history).

Principles: every Toolkit safety tool is free forever, including during an outage. One subscription group with
three annual tiers and a 7-day free trial. Nothing is sold outside the App Store. No account is required; purchases are tied to the Apple ID and shared
through Apple Family Sharing so a spouse does not pay twice.

### The ladder

| | Free | Duo | Family 6 | Family 10 | Group 50 |
|---|---|---|---|---|---|
| Price | $0 | $7.99 / yr | $12.99 / yr | $19.99 / yr | $49.99 / yr |
| People in your house | 1 | 2 | 6 | 10 | 10 (organizer's house) |
| Households in the group | | | | | up to 50 |
| Items | 50 | unlimited | unlimited | unlimited | unlimited |
| Pets | unlimited | unlimited | unlimited | unlimited | unlimited |
| Free trial | | 7 days | 7 days | 7 days | 7 days |
| Toolkit (SOS, outage mode, contacts, plan, know-how, medication card, compass, radio, games) | all, always | all | all | all | all |
| Scanning, shelf-life library, readiness math, PDFs, CSV | yes | yes | yes | yes | yes |
| Kits, maintenance reminders, seasonal checklists, documents vault, widgets, sync | no | yes | yes | yes | yes |
| Profile links and medication cards | first person | both | all | all | all |
| Group roster, readiness roll-up, shared contacts and plan | | | | | yes |

What moves someone up: adding a second person or passing 50 items moves Free to Duo (Family 6 is offered
beside it). The third person moves Duo to Family 6, the seventh moves Family 6 to Family 10; Apple prorates
on the way up and applies downgrades at renewal. A person living alone with more than 50 items pays Duo.
Store page: "Free until you need it. Duo from $7.99 a year, Family from $12.99."

### Group 50, defined

"50" counts households, not people, so it is a different unit from the Family tiers:
- The organizer's own household gets Family 10.
- Up to 50 member households join with the free app and keep their own Free tier.
- Everyone gets the group features: roster (name, people and pets counts, readiness in days; never inventory),
  readiness roll-up for the organizer ("6 of 31 households under 3 days of water"), shared contacts and plan,
  and opt-in medication cards.
- A member who wants unlimited items or more than one person in their own house buys Family themselves.
This keeps Group from cannibalizing Family, keeps it on Phase 2 CloudKit sharing with no server, and makes every
member household a future Family customer. The gap between Family 10 and Group 50 is deliberate; add a middle
tier only if the data asks for it.

### Trial and paywall rules

- 7-day free trial on first subscription, once per Apple ID (App Store introductory offer on the group).
- The paywall appears when someone adds a second person, passes 50 items, or opens a paid screen. Let them add
  the person and see "covered for 4 days" first, then offer the trial.
- The paywall never appears inside Outage mode or any Toolkit tool.
- Subscription group ranks: Duo < Family 6 < Family 10 < Group 50 (App Store Connect levels 4, 3, 2, 1), so
  upgrades and downgrades behave correctly.

### Paywall as built (November 3, 2026)

- StoreKit 2, one subscription group "Lantern Plan" with `family6`, `family10`, `group50` yearly products, 7-day
  free introductory offer, Family Sharing on. `Config/Lantern.storekit` mirrors it for the simulator; the shared
  scheme points at it. Group 50 is defined but hidden (`PlanStore.showsGroupTier`) until group features exist.
- `PlanStore` reads `Transaction.currentEntitlements`, highest plan wins, listens to `Transaction.updates`.
  Launch argument `-plan family6` fakes a plan in Debug builds.
- Gates: 51st item (hard, in the item editor and starter packs); second person (soft: the person is saved, then
  the paywall opens with "Your household is covered for N days"); seventh person offers Family 10; medications,
  profile links and the medication card for people beyond the plan show a locked row; equipment reminders only
  schedule on a paid plan. Home shows "Your plan covers 1 of N people" while over the limit.
- Never shown inside the Toolkit. Settings has "Your plan" with restore and manage links.
- Needs before shipping: real Privacy and Terms pages at the URLs in `Legal`, the products created in App Store
  Connect with the same IDs, and the App Store Small Business Program enrolment (15% commission).

### What stays free in an emergency

The Toolkit is deliberately outside the paywall. If someone downloads Lantern during a hurricane watch, the SOS
strobe, fridge and freezer clocks, emergency numbers, NOAA frequencies and first-aid cards must work in the first
thirty seconds with no purchase prompt. The upgrade prompt only ever appears when a user hits the 50-item limit or
opens a Pro-only screen, and never during an active outage in Outage Mode.

## 12. Voice (not branding)

Branding, name and visual identity are deferred. Voice should still be decided early because it shapes copy in every screen.

- Say: ready, stocked, supplies, use first, bad week, outage, storm, "keep extra of what you already buy."
- Avoid: prepper, survival, SHTF, bug out, tactical, apocalypse, doomsday, mission, loadout, threat.
- Tone: a competent friend who has been through a few outages. Short sentences. No fear.
- Readiness is shown as "You're covered for 9 days of water" rather than a percentage score.

## 13. Roadmap

| Weeks | Milestone |
|---|---|
| 1 to 2 | Data model, FoodKeeper import, deep-storage table v1, maintenance table v1 |
| 3 to 5 | Inventory, locations, barcode and date scanning, quick quantity controls |
| 6 to 7 | Alerts, weekly digest, rotation queue, water fill dates |
| 8 to 9 | Equipment records, maintenance schedules and logs, battery tracker |
| 10 | Readiness view, household setup, gap shopping list |
| 11 | Export, backup, onboarding with three questions and starter packs |
| 12 | TestFlight beta, 30 to 50 testers |
| Phase 2 | Kits, sharing, seasonal checklists, documents, meds (roughly 10 more weeks) |

**Beta recruitment:** r/TwoXPreppers and r/preppers both restrict self-promotion, so ask moderators first or recruit via the CastleWise beta list, theprepared.com forum, and homesteading and frugal-living groups. Pitch it as "a pantry and supplies tracker that works offline," not as a prepper app.

**Success signals for the MVP:** testers still logging items after 4 weeks (the abandonment problem), weekly digest open rate, number of items with a scanned date versus typed, and whether anyone exports a PDF.

## 14. Risks and open questions

- **Date OCR accuracy.** Printed dates vary wildly. Ship it as "scan then confirm," never auto-commit. Measure confirmation edits in beta.
- **Open Food Facts coverage** for US store brands is uneven. Local product memory and starter packs cover the gap.
- **Sharing complexity.** Phase 2, not MVP. Do not promise it until it is reliable.
- **Scope creep.** The backlog in section 7 is long on purpose. The MVP is inventory, alerts, equipment, readiness, export. Nothing else.
- **Tone drift.** Experienced preppers will ask for ammo categories and threat levels. A custom category covers it without changing the voice.
- **Content maintenance.** Government pages change (Ready.gov is mid-revision). Keep source URLs and a "last checked" date on every library entry.
- **Open question:** does this live inside CastleWise (it already has a free "Emergency mode") or as a separate app? Research favors a separate app with its own audience and store listing, sharing code and the Expert Check backend. A homeowner-tool brand will not reach renters and apartment dwellers, who are a large share of the target audience.

## 15. Research caveats

- Reddit itself was unreachable from this environment. Reddit signal came from Slate, MetaFilter and Yahoo coverage of r/TwoXPreppers and r/UKPreppers threads, plus theprepared.com and survivalistboards.com forums, which were reachable via search snippets only.
- App Store pages were also blocked, so ratings and review quotes come from search snippets and aggregators and should be treated as approximate.
- Government sites (ready.gov, cdc.gov, fsis.usda.gov) were blocked, so those facts were confirmed against archived copies and mirrors. Re-verify exact wording before shipping library content.

## 16. Sources

**Audience and pain points**
- https://slate.com/technology/2022/03/reddit-preppers-sub-women-splitting-off-twoxpreppers.html
- https://www.metafilter.com/194896/Your-doomsday-is-our-Tuesday
- https://theassessment.substack.com/p/prep-for-tuesday-not-doomsday
- https://www.yahoo.com/lifestyle/articles/uk-prepper-opens-undamaged-food-090100448.html
- https://www.yahoo.com/lifestyle/articles/stock-straight-away-uk-preppers-232500874.html
- https://uk.news.yahoo.com/uk-mum-ran-money-emergency-113300016.html
- https://www.yahoo.com/lifestyle/articles/uk-preppers-want-rebrand-less-133700937.html
- https://www.yahoo.com/lifestyle/articles/meet-women-redefining-prepping-practical-110000867.html
- https://theprepared.com/forum/thread/food-prep-inventory-tracking/
- https://theprepared.com/forum/thread/prepping-organization-diary-journals-todo-lists-etc/
- https://theprepared.com/forum/thread/water-storage/
- https://theprepared.com/forum/thread/first-aid-expiration-dates/
- https://theprepared.com/forum/thread/newbie-prepper/
- https://theprepared.com/forum/thread/dealing-with-a-spouse-significant-other-who-thinks-prepping-is-nuts/
- https://www.survivalistboards.com/threads/how-do-you-inventory-your-preps.271163/
- https://www.survivalistboards.com/threads/prep-organization-the-best-prep-inventory-system.978290/
- https://www.survivalistboards.com/threads/pantry-inventory-app-software.1004774/
- https://tryinstock.com/blog/pantry-inventory-spreadsheet-vs-app/
- https://www.wellstockd.com/blog/shared-pantry-app
- https://www.xda-developers.com/grocy-seemed-like-a-great-self-hosted-tool-until-i-used-it-for-a-week/
- https://modernsurvivalblog.com/preps/time-to-run-your-generator/
- https://www.finder.com/doomsday-prepper-statistics
- https://www.safehome.org/research/home-emergency-preparedness-study/
- https://www.globenewswire.com/news-release/2026/09/15/3362270/0/en/only-13-of-americans-have-an-emergency-plan-first-onsite-survey-finds.html
- https://www.cnn.com/2025/06/17/climate/left-wing-liberal-preppers
- https://theweek.com/defence/be-ready-prepping-goes-mainstream
- https://time.com/7000176/costco-sells-emergency-food-bucket/

**Competitors**
- https://apps.apple.com/us/app/pantry-check-grocery-list/id966702368
- https://apps.apple.com/us/app/nowaste-food-inventory-list/id926211004
- https://apps.apple.com/us/app/fridgely/id988016972
- https://apps.apple.com/us/app/grocy-mobile/id1567803209
- https://apps.apple.com/us/app/prepperpro/id6743128293
- https://apps.apple.com/app/id6741197301
- https://apps.apple.com/us/app/preppr-learn-stock-survive/id6670330104
- https://apps.apple.com/us/app/inventory-wolf/id1514682383
- https://apps.apple.com/app/id431188993
- https://apps.apple.com/us/app/go-bag-emergency-disaster-kit/id1619012440
- https://beagleprep.com/blog/best-prepper-inventory-apps/
- https://www.askaprepper.com/ppantry-app-review-the-best-free-tool-for-tracking-your-emergency-supplies/
- https://thesurvivalmom.com/best-food-storage-app/
- https://pare.recipes/blog/best-pantry-inventory-apps
- https://www.capterra.com/p/169199/Sortly-Pro/reviews/
- https://appfollow.io/ios/fema/474807486?country=us
- https://appgoblin.info/apps/954783878
- https://glenbrook.com/payments_news/us-subscription-fatigue-is-real-with-consumers-managing-an-average-of-5-accounts/

**Official guidance and data**
- https://catalog.data.gov/dataset/fsis-foodkeeper-data
- https://www.foodsafety.gov/keep-food-safe/foodkeeper-app
- https://www.ready.gov/kit
- https://www.redcross.org/get-help/how-to-prepare-for-emergencies/survival-kit-supplies.html
- https://www.cdc.gov/water-emergency/about/how-to-create-and-store-an-emergency-water-supply.html
- https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics/food-safety-during-power-outage
- https://www.fda.gov/food/buy-store-serve-safe-food/confused-date-labels-packaged-foods
- https://www.churchofjesuschrist.org/study/manual/food-and-water-storage/long-term-food-and-water-storage
- https://pubmed.ncbi.nlm.nih.gov/16721796/
- https://www.cpsc.gov/Newsroom/News-Releases/2023/New-CPSC-Report-Shows-Upward-Trend-in-Carbon-Monoxide-CO-Fatalities
- https://www.ready.gov/sites/default/files/2020-03/ready_emergency-financial-first-aid-toolkit.pdf
- https://www.ready.gov/pets
- https://www.nfpa.org/education-and-research/home-fire-safety/smoke-alarms
- https://dps.mn.gov/divisions/sfm/services/inspections/hotels-and-motels/hotel-fire-extinguishers
- https://support.generac.com/articles/Knowledge/How-Often-Should-I-Perform-Routine-Maintenance-on-My-Portable-Generator
- https://www.jackery.com/blogs/buying-advice/how-long-does-a-jackery-hold-a-charge
- https://www.redcross.org/take-a-class/resources/articles/do-first-aid-kits-expire
- https://www.law.cornell.edu/cfr/text/49/180.209
- https://www.osti.gov/servlets/purl/1860579
- https://readyforwildfire.org/wp-content/uploads/2025/04/1-Hour-Wildfire-Ready-Checklist.pdf
- https://www.weather.gov/news/240103-spring-safety-campaign
- https://www.insurancejournal.com/news/national/2024/06/20/780393.htm
- https://developer.apple.com/app-store/review/guidelines/

**Technical**
- https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/license-be-on-the-legal-side/
- https://support.openfoodfacts.org/help/en-gb/12-api-data-reuse/94-are-there-conditions-to-use-the-api
- https://nonstrict.eu/wwdcindex/wwdc2022/10025/

---

## 17. Name candidates (added November 2, 2026)

Brief: calm, mainstream, household. Says "get through a bad week," never "survive the end." Should be easy to say
and spell, work as an App Store title with a subtitle, and sit comfortably next to a Costco receipt rather than a
bunker. Web search was used to check for same-name apps in this category; apps.apple.com and USPTO were not
reachable from this environment, so every finalist still needs a store search and a trademark search.

| Name | Why it fits | Tagline sketch | Conflicts found |
|---|---|---|---|
| **Tide Over** (recommended) | "Enough to tide you over" is the exact promise: get through, not survive. Gentle idiom everyone knows. Zero tactical energy. | Enough to tide you over. | None in apps or trademarks. "Tide" detergent and Tide banking are unrelated classes; still check. |
| **Lantern** | The object you reach for when the lights go out. Warm, protective, domestic. Reads well as an icon. | Ready for the dark. | No preparedness or pantry app. A defunct 2014 DoE Android app "Lantern Live." Common word; expect other Lanterns in unrelated categories. |
| **Just in Case** | The phrase non-preppers already use to explain the extra case of water. States the whole philosophy. | Keep a little extra, just in case. | No preparedness app found. Generic phrase, weak trademark, poorer search discoverability. |
| **Backstock** | Retail term for the extra inventory in the back room. Precise: this audience has a backstock, not a bunker. Distinctive and ownable. | Know what's in the back. | None found. Slightly insider; less warm than the others. |
| **Rainy Day** | "Saving for a rainy day." Planning without fear, fully mainstream. | For a rainy day. | Several unrelated apps named Rainy Day (sleep sounds, a finance game). Crowded word, discoverability cost. |
| **Tuesday** (wildcard) | From the community's own line, "prep for Tuesday, not doomsday." Opaque alone, memorable with a subtitle. | Ready for Tuesday. | None found in category. Generic word, weak trademark. |
| **StockWise** (in-family option) | Sibling to CastleWise if you ever want a family of "-Wise" apps. | The stocked-up house. | "Stock" leans financial. Only worth it if the family brand matters. |

Rejected after checking: Larder (two pantry apps), Squirrel (direct competitor "Squirrel: Home Inventory"),
Kept (home inventory app), Shelf Life (four apps), Provisions ("PROvisions: Expiry Tracker" exists),
Stocked and Stockpile (existing competitors), anything with Prep, Ready, Survival or Shield in it.


## 18. Decisions log

- 2026-11-03: Name is Lantern. Tagline: "Ready for when you need it most." Supporting line: "Know what you have."
- 2026-11-03: Medications carry the whole label: form, strength, purpose, clock times, how-to-take and warning
  instructions from a fixed catalog (take with food, do not drive, avoid alcohol...), prescriber, pharmacy, Rx number,
  optional dose reminders. A Medication card (Toolkit) shares the household's medications as text or PDF.
- 2026-11-03: Profiles travel as links (`lantern://profile/new`, `lantern://profile/import`), so family members build their own profile and send it back. No server.
- 2026-11-03: Toolkit tab added; every Toolkit tool is free on every tier. No pre-written message templates.
- 2026-11-03: Built kits, universal links, trusted contact, demo data, App Store screenshots (docs/screens/appstore on the Mac), Icon Composer icon. Device build installed on the iPhone 16 Pro Max without the associated-domains entitlement (Release only until the capability is enabled with an Apple ID in Xcode).
- 2026-11-04: Duo added (1.0.1): two people, $7.99/yr, 7-day trial, Family Sharing on, product
  io.kismetstudio.lantern.duo (App Store Connect 6830816212, group level 4). Reasoning in §23.
- 2026-11-03: Pricing final for now: Free (1 person, 50 items); Family 6 $12.99/yr; Family 10 $19.99/yr; Group 50 $49.99/yr (50 households, organizer gets Family 10, members stay Free); No Organizations tier. 7-day trial. Toolkit free on every tier. No solo plan, no one-time purchase.
- 2026-11-03: No amber buttons. Amber is light only (icon, glow, progress, active tab). Buttons are Ink on light, Paper on dark.
- 2026-11-03: Onboarding captures people, not headcounts: name, age, weight, height (optional), sex, activity level,
  medications (dose, times per day, units on hand), allergies and dietary notes, plus pets by species and weight.
  Food readiness is computed in calories per person per day (Mifflin-St Jeor when height and weight are known,
  Dietary Guidelines age bands otherwise). Medicine readiness is days of supply per medication, with critical
  medications flagged. Infants switch the food target to formula.

## 19. Toolkit (added November 3, 2026)

A fifth tab. Everything a phone can *do* in an emergency, as opposed to what it can track. Built in one pass;
all of it is free on every tier. No pre-written message templates (decided against: they read as canned).

**Outage Mode (hero card)**
- Start and end an outage with one tap; the start time is recorded as an `OutageEvent`.
- Live fridge clock (USDA: 4 hours unopened) and freezer clock (48 hours full, 24 hours half full) with a
  "freezer is full" toggle and a counter for how many times the fridge door has been opened.
- "What you have right now": lights, batteries and water pulled from the inventory, plus the household's daily
  water need so the user can see the gap.
- Phone battery level and charging state with concrete tips for stretching it.
- Generator, carbon monoxide and food-safety cards linked from the know-how library.
- Optional "check in" reminder every N hours (local notification) so someone remembers to text family.
- Outage history, so a user can show the power company or insurer when it started and ended.

**Light**
- Torch patterns through the camera flash: steady, slow blink, Morse SOS (… --- …). Warns at ten minutes
  about battery drain.
- Full-screen light modes: bright white, warm amber (easier on eyes at night), flickering candle, and a
  high-contrast flasher. Screen brightness is pushed to maximum and the idle timer is disabled while open.

**Sound**
- Alarm whistle: a loud synthesized two-tone alarm for attracting attention. The button is tinted Ember while
  it runs so it cannot be left on by accident.
- White noise, rain, pink and brown noise for sleeping through a storm or a generator, with a stop-after timer.

**Information**
- Emergency contacts: 911, Poison Control, 211, FEMA helpline and the Disaster Distress Helpline are seeded
  and cannot be deleted; the user adds their own. Each row dials with one tap. Printable PDF.
- Household plan: two meeting places (near home, outside the neighbourhood), out-of-town contact, where the
  pets and kids go, medical notes, where documents are kept. Reviewed-on date. Printable PDF to stick on the
  fridge.
- Shutoff locator: notes and a photo for the gas, water and electric shutoffs, so a babysitter or teenager can
  find them.
- Know-how cards: thirteen short, numbered procedures sourced from CDC, USDA, FEMA, Red Cross and NWS
  (water disinfection, fridge and freezer rules, generator placement, CO alarm response, gas and water shutoff,
  bleeding, burns, heat illness, hypothermia, flood water, satellite SOS, understanding alerts). Each card
  links its source and carries a "not medical advice" disclaimer.
- Compass: a plain magnetic compass using Core Location heading, with permission and unavailable states.
- Signals: how Wireless Emergency Alerts work with a shortcut to the Settings toggle; the seven NOAA Weather
  Radio frequencies with a field to remember the local station; a pointer to Apple's Emergency SOS via
  satellite and how to reach it.

**Medication card**
- Every medication records form, strength, what it is for, the clock times it is taken, how to take it and what to
  avoid (chosen from a catalog of standard label instructions so the wording matches the pharmacy), free-text
  extras, prescriber and phone, pharmacy and phone, Rx number, on-hand count, expiry, and an optional local
  reminder at each dose time (time-sensitive for can't-miss medications).
- The card lists every person's medications with allergies, shareable as plain text to a group chat or a
  caregiver, or as a PDF for the fridge and the go-bag. Each person also has a share link on their own screen.

**Profile links (people builder)**
- Household → "Ask someone to add themselves" sends a plain-text message with a `lantern://profile/new?from=Tim`
  link. On the family member's iPhone it opens a profile builder in a scratch store (it never touches their own
  household): the same person and medication screens, then "Send to Tim".
- That reply is a `lantern://profile/import?d=…` link carrying the whole profile as base64url JSON (name, age,
  size, sex, activity, allergies, diet, notes, every medication with times, instructions, prescriber, pharmacy).
  Tapping it on the owner's phone shows a preview and "Add to household" or "Update" when the name already exists.
- No server, no account. The link is the transport. Follow-up: a universal link domain so the same link opens the
  App Store for people who do not have Lantern yet; today the message tells them to install it and tap again.

**Pass the time**
- Dice (animated SF Symbol die faces), coin flip, and a 52-card deck to draw from and shuffle. For kids in the
  dark with no Wi-Fi.

Rules observed: HIG-compliant layouts, animated SF Symbols, no amber buttons, every action has an accessibility
label, every tool works offline, nothing here needs a purchase.

## 20. Dashboard, fuller profiles, nutrition facts (added November 4, 2026)

**Home as a dashboard**
- A household strip at the top: a circle per person (initials; a bolt badge when they depend on power, a pill
  badge when they have medications, an ember dot when the profile is only a name) and per pet, plus Add. Tapping
  a circle opens that profile. A line underneath reads "3 people · 1 pet · covering 14 days" and opens Household.
- "Where you stand": Food, Water, Medication (shortest supply) and Pet food or Equipment tiles, then three chips:
  items to use or check, shopping list size, gaps.
- "Close the gaps": the first three readiness gaps with Add to shopping list. "Who can do what": power-dependent
  people with the matching hint, anyone who needs help to leave, each person's job, every skill with the names
  that have it, and one nudge when nobody is marked for first aid, CPR, utility shutoff or the generator.
- Use this week and Equipment this week stay as they were.

**Fuller person profile**
- Contact (phone, who to call about them). Health (blood type, conditions, mobility). Runs on power (CPAP,
  oxygen, insulin in the fridge, nebulizer, power wheelchair, home dialysis, pumps, hearing aids, lift, phone),
  each with a short hint. Skills from a 30-entry list in five groups (medical, practical, outdoors,
  communication, care), languages, can drive. Wellness (what to know, what helps). In an emergency (their job
  and anything else). More: "Add a field" for label/value pairs the app did not think to ask for.
- All of it travels in the profile link (card version 2, old cards still decode) and the health lines go on the
  medication card.

**Nutrition facts**
- Food items carry the label panel per serving: serving size, calories, fat, sodium, carbohydrate, fiber,
  sugars, protein, with the source (label or Open Food Facts). The barcode lookup now pulls the per-serving
  figures, scaling from per-100 g when the serving size is known. The editor has a Nutrition facts toggle and a
  one-tap "use N calories per unit for readiness"; the detail screen shows the panel, calories and protein on
  hand, and how long the item feeds one person or the house.
- Product memory remembers the panel so the second scan is one tap.

**Supplies selection**
- The action bar while selecting now sits above the tab bar (it was a toolbar the tab bar hid): Category, Move,
  Kit (when kits exist) and Delete. Every item has a category; the bar changes it in bulk.

## 21. Launch kit (added November 4, 2026)

`docs/launch/` holds the launch kit, built to the CastleWise standard: README-START-HERE, the command
center (six tabs, launch date drives every day), punch list, Facebook and Messenger copy, beta tester
heads-up and thank-you with offer codes, Reddit posts and the Reddit Ads build sheet, Apple Ads keyword
plan, press release and fact sheet, review reply templates, the four-week Facebook content plan, pricing
plan, launch lessons (CastleWise's eleven applied), social images, QR code, calendar file and the scripts
that made them. The press page is live at kismetstudio.io/lantern/press/; the live version of the Lantern
page waits on branch `lantern-live` of the site repo.

## 22. Pass the time, done properly, and ready-to-send texts (added November 4, 2026, for 1.0.1)

The TestFlight note "add as much as you can [to] pass the time" was misread as filler during the 1.0 rush,
so 1.0 shipped with dice, a coin and a deck. 1.0.1 makes it a real section. Every game is on the phone,
needs no signal, and most are played with one phone passed around.

**Quick:** dice, cards and a coin (the deck now draws as card faces); rock, paper, scissors against the
phone with a running score; who goes first, which spins through the household's names (plus guests) and
can split two teams.

**One phone, two players:** tic-tac-toe (loser starts the next game), four in a row (seven by six, win
highlighted), hangman (the phone picks from its word lists with a category hint, or a friend types the
word hidden), draw and guess (finger drawing on a canvas, three brush sizes, undo, a 90-second clock, the
word shown only to the artist).

**Everyone:** heads up (word on the forehead, tilt down for right and up for pass via CoreMotion, with
buttons as the fallback, 30/60/90-second rounds, seven categories of 40 words); act it out (charades
with the same lists and clock); would you rather (60 pairs, tap to vote); twenty questions (the phone
keeps the secret, hold to peek, a 20-question counter); trivia (ten per round, half readiness facts from
the know-how sources with a one-line note after each answer, half general knowledge for kids, 70
questions in the bank, best score kept); story chain (30 openers, 30 twists); flashlight scavenger hunt
(eight prompts, five-minute clock); shadow puppets (nine, step by step, with a link to the flashlight).

**Just you:** memory match (6, 8 or 12 pairs of SF Symbols), repeat after me (four pads, pattern grows
by one, best round kept), guess my number (1 to 100, fewest guesses kept).

Rules kept: no amber buttons (amber only on progress bars and the spinner dot), neutral tints on game
controls, accessibility labels on every tile and pad, no em dashes, none of the banned words. Logic for
tic-tac-toe, four in a row, hangman, number guess, Simon and rock-paper-scissors lives in GameLogic.swift
and is tested; the word banks are tested for size, uniqueness and banned words.

**Ready-to-send texts** (Toolkit, "Tell people you're okay"): five messages ("We're safe", "We're
leaving", "We made it", "We need a hand", "Checking on you") plus "Meet at our spot" when the plan has a
meeting place. Each is filled from the household names, the outage start time and the plan's meeting
spots, then Text (opens Messages with the body, you pick who), Share, or Copy. The user's own emergency
contacts appear as a second list: tap a name, pick a message, Messages opens addressed to them. The
message builder is a static function and tested.

## 23. Duo (added November 4, 2026, for 1.0.1)

**What it is.** A paid plan for two people in one house: everything Family 6 has (unlimited items and kits,
both people's medications and medication cards, profile links, equipment reminders), capped at two people.
$7.99 a year, 7-day free trial, Family Sharing on. Product `io.kismetstudio.lantern.duo`, group level 4,
the bottom of the paid ladder.

**Why.** Two-adult households without children at home are the single largest household type in the
United States, about three in ten, and one-person households are another three in ten. The second-person
paywall is the moment most of them meet Lantern's price, and "Family 6, $12.99" reads wrong to a couple on
both words: they are not a family of six and they are being asked to pay for four empty seats. Duo fixes the
name and the price for the largest segment at once. It also gives the person living alone who passes fifty
items a plan that sounds like it was meant for them, which the November 3 decision ("no solo plan") left
without an answer.

**Why it does not undercut Family.** The cap is enforced in the app: the third person triggers the Family 6
paywall, and Apple prorates the upgrade inside the subscription group. A family of four cannot stay on Duo.
The earlier objection to a Solo tier ("a discount that cannot be enforced") does not apply, because every
paid plan now caps people and the cap is the product.

**Money.** Net per Duo subscriber after the Small Business Program is about $6.79, against $11.04 for
Family 6. Duo pays for itself if, among households that see the second-person paywall, it converts at
better than 1.6 times the rate Family 6 would have. For couples, that is the bet. The Day 30 rule in
pricing-plan.md still stands: nothing moves until 100 downloads and 30 days, and the number to read is
revenue per download, not conversion.

**Paywall as built.**
- Second person or 51st item: Duo first and selected, Family 6 beside it. Subhead names both.
- Third person on Duo: "Three or more in the house? Family has room." Family 6 selected, Family 10 beside it.
- Seventh person: Family 10 only, as before. Settings, See plans: Duo, Family 6, Family 10.
- Home banner reads "Your plan covers 2 of 3 people" on Duo; the trial line no longer names Family.
- `Plan.needed(forPeople:)` returns Duo for two. `-plan duo` fakes it in Debug. `Config/Lantern.storekit`
  carries the product at group number 4 so the simulator shows the real paywall.

**Store and site.** The App Store description paragraph and the website plans section show three cards:
Free, Duo, Family. Group 50 stays hidden. Offer codes for testers stay on Family 6.

**Not done until 1.0 is approved.** The Duo product is created and priced in App Store Connect but reads
"Ready to Submit"; it goes into the 1.0.1 review submission with build 7 or later, the same way Family 6 and
Family 10 went in with 1.0 (web UI, Add for Review, the draft). The 1.0 description in App Store Connect is
not touched while 1.0 is in review; the new paragraph goes in with 1.0.1.

## 24. iPhone Duo (added November 5, 2026, for 1.0.1)

The foldable has two screens: the outer one at 466 by 678 points when closed (a short, wide phone) and
the inner one at 669 by 951 points when open (an iPad mini's shape). Lantern treats them as two layouts.

**Closed.** The phone layout, unchanged. iOS puts the tab bar down the right edge on this aspect; nothing
in the app assumes a tall screen except the games, which already fit the 6.1-inch phone.

**Open, side by side.** Any window 600 points or wider is promoted to the regular width class
(`wideWindowSizeClass()` on the root), and the five tabs are built on `SplitContainer`, a
NavigationSplitView that collapses to the old single column on a phone. On the open Duo: Home keeps the
dashboard on the left with the household on the right, and whatever you tap on the left opens on the
right; Supplies is the list beside the item; Equipment the list beside the gear; Ready beside the
household; Toolkit is the tool list beside Outage mode, and every tool, game and card opens in the right
column.

**Across the hinge.** Rock, paper, scissors gains a two-player mode on wide screens: the top half is
turned to face the person across the table, each picks on their own half, and nothing shows until both
have picked. The pattern is in `HeadToHeadRPS` for the next game that wants it.

**Half open on a table.** `HingeMonitor` wraps `UIHingeInteraction` (iOS 27.1) and reports closed,
partially open or fully open. Dice, cards and a coin uses it: half open, the results sit on the upright
half and the buttons on the flat half. Phones without a hinge never see it.

**Verified.** Closed on the iPhone Duo simulator. Open on an iPad mini at the regular width class, since
Xcode 27.2's simulator exposes the inner display but no way to fold the device from the command line;
the inner display stays dark when powered on its own. The hinge code compiles against the 27.2 SDK and
is guarded by availability; it has not run on a hinge.

## 25. Review pass (November 5, 2026, build 10)

A full read of Views and Services against §20 to §24 and hig.md turned up forty items. Fixed in build 10:

- **Plans.** One source for plan copy (`Plan.peopleLine`, `Plan.next(forPeople:)`). The paywall, Settings,
  the Home banner and every locked row name the next plan up, so a Duo household never sees Family copy or
  a dead-end sheet; a Family 10 household never sees the banner at all. Settings offers "Move up a plan" to
  paid users. The 50-item limit now holds inside kits ("Still missing" rows and "Add every item on the
  list"). Deleting a person asks first.
- **Crashes and clocks.** Memory match looked tiles up by index after a redeal; now by id. Who goes first
  could index past a deleted name during a spin; delete is off while spinning. The game clock was a new
  Timer per redraw, which stalled while drawing; it is one task per screen. Heads up no longer starts after
  you leave the countdown, and the tilt starts disarmed.
- **Copy.** Equipment is Gear everywhere, including Onboarding and Home. Status texts drop the outage
  clause when no outage is running and use I/we for a household of one. Plurals fixed in readiness gaps,
  memory match and kit badges. The medication card's em dash is gone. "Free" is out of the paywall
  headlines. Water shows gallons in Outage mode and Ready, not litres. Zero people reads "No one added yet".
- **Colour rules.** Amber only on progress, the tab bar and the onboarding and paywall symbols; every other
  amber icon is ink. Signal only on expired medicine; game losses and errors use ember, playing cards a
  plain red. Simon's fourth pad is grey, not primary, so it reads in Dark Mode.
- **Toolkit.** A running SOS light or alarm shows at the top of the Toolkit with a Stop button, since both
  keep going after you leave their screen. The light's battery warning re-reads every minute. The
  screen-awake hold is reference counted so one tool cannot clear another's.
- **Who can do what.** Every line opens the person it names, skills list tappable names, and there is a
  link to the whole household. Before anyone is marked, each person is listed with "Mark skills".
- **Accessibility.** Four-in-a-row cells, trivia marks, dice and cards have labels; the contact row and
  "Hold to peek" have VoiceOver actions; the Supplies empty state stacks at large type; the location
  symbol menu is labelled; the onboarding bulb is hidden from VoiceOver.
- **Dead code.** The duplicate share sheet, the duplicated gap rows (now `GapRow`, which reads the shopping
  list instead of a per-screen set), an unused library reference and an unused requester name.

Left for later, in order: Home person bubbles open sheets rather than the detail column on the open Duo;
"3d overdue" style durations are terse for VoiceOver; the per-position coverage rule (first N people in
sort order are covered) is kept but not yet explained in Settings.
