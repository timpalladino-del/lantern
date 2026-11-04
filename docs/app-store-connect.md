# App Store Connect setup for Lantern

Everything the paywall expects, so the products can be created in one sitting. The IDs must match exactly;
they are hard-coded in `Lantern/Services/PlanStore.swift` and mirrored in `Config/Lantern.storekit`.

## App record

- Bundle ID: `io.kismetstudio.lantern` (team 69MM5TC2UN)
- Name: Lantern: Household Readiness (plain "Lantern" is taken on the App Store; the home-screen name stays Lantern)
- Subtitle: Ready when you need it most
- App record id 6830418364, bundle ID record RLY753X48D, subscription group 22542888.
- Primary category: Lifestyle. Secondary: Utilities.
- Privacy policy URL: https://kismetstudio.io/lantern/privacy/
- Terms of use (EULA): https://kismetstudio.io/lantern/terms/ (enter in the App Information "License Agreement" field, and in the paywall it is linked)
- Support URL: https://kismetstudio.io/lantern/
- Age rating: 4+. Medical/treatment information: "Infrequent/Mild" (medication tracking is user-entered, not advice).
- App Privacy (nutrition label): Data Not Collected. The only network call is the optional Open Food Facts barcode lookup, which sends the barcode digits and no identifier; Apple's definition of "collected" is data sent off-device that is linked or used, so declare "Data Not Collected" and keep the privacy policy's barcode paragraph accurate.

## Subscription group

Create one group. Rank matters: Apple uses it for upgrade/downgrade proration.

| Field | Value |
|---|---|
| Group reference name | Lantern Plan |
| Group display name (App Store localization, en-US) | Lantern Plan |

## Subscriptions (all auto-renewable, duration 1 year)

| Reference name | Product ID | Rank in group | Price (US) | Display name | Description |
|---|---|---|---|---|---|
| Family 6 | `io.kismetstudio.lantern.family6` | 3 (lowest) | $12.99 | Family 6 | Up to 6 people in your house, unlimited supplies. |
| Family 10 | `io.kismetstudio.lantern.family10` | 2 | $19.99 | Family 10 | Up to 10 people in your house, unlimited supplies. |
| Group 50 | `io.kismetstudio.lantern.group50` | 1 (highest) | $49.99 | Group 50 | Up to 50 households, for organizers. Includes Family 10 for your own house. |

Group 50 is created now so the ID is reserved, but it is not shown in the app (`PlanStore.showsGroupTier = false`).
Leave it in "Ready to Submit" and do not attach it to the first version's in-app purchases if you prefer; the
app ignores it either way.

For each subscription:
- Availability: all territories. Apple will auto-generate other currencies from the US price tier; accept them.
- Family Sharing: **On**. (Once on, it cannot be turned off.)
- Introductory offer: Free, 1 week, one per customer, all territories. Start date today, no end date.
- Review notes: "Local-first app. The paywall appears after adding a second household member or passing 50
  items. Use the attached screenshots. The free Toolkit tab is fully usable without purchase."
- Screenshot for review: the paywall screenshot in `docs/screens/paywall.png`.

## Tax and banking

Paid Apps agreement must be Active, with banking and tax forms complete, before subscriptions can be tested in
TestFlight or sandbox. Small Business Program: already enrolled.

## Sandbox testing

1. App Store Connect → Users and Access → Sandbox → add a sandbox Apple ID.
2. On a device: Settings → App Store → Sandbox Account → sign in.
3. Run a TestFlight or Xcode build. Subscriptions renew every few minutes in sandbox (1 year = 1 hour).
4. In the simulator you do not need any of this: the scheme uses `Config/Lantern.storekit`.

## Associated Domains (universal links)

The Release configuration signs with `Config/Lantern.entitlements` (`applinks:kismetstudio.io`). Before the first
archive: Xcode → Settings → Accounts → add the Apple ID for team 69MM5TC2UN, then in the Lantern target →
Signing & Capabilities → + Capability → Associated Domains. Xcode registers it on the App ID. Debug builds do not
use the entitlement so device builds work without it; profile links fall back to the `lantern://` scheme via the
page on the site.

## TestFlight

`xcodebuild -scheme Lantern -configuration Release archive` then upload with Xcode Organizer or Transporter. Both
need the Apple ID signed in on the Mac; nothing in the repo blocks it once the App Store Connect record exists.

## State on November 4, 2026 (done through the API)

- App record 6830418364 "Lantern: Household Readiness", bundle ID record RLY753X48D with Associated Domains.
- Subscription group 22542888 "Lantern Plan": family6 6830418767, family10 6830418569, group50 6830418741.
  All three READY_TO_SUBMIT: en-US localizations, Family Sharing, prices in 175 territories from the US tier,
  7-day free trial in every territory, review screenshot (the paywall).
- Version 1.0 in PREPARE_FOR_SUBMISSION with build 1 attached, export compliance set, description, keywords,
  promo text, support and marketing URLs, privacy URL, subtitle, categories (Lifestyle / Utilities), age rating
  (medical info infrequent/mild, everything else none), copyright, manual release, nine 6.9-inch screenshots.
- TestFlight: build 1 processed, "what to test" set, internal group "Kismet internal" created.
- Scripts that did it live on the Mac in ~/.appstoreconnect (asc.py is the client; the rest are one-shot passes).

Left for a person: add yourself as an internal tester in the TestFlight tab, accept the updated Program License
Agreement, App Review contact phone number, then Submit for Review.

## Checklist

- [ ] App record created with the bundle ID above
- [ ] Privacy policy and terms URLs entered
- [ ] Subscription group "Lantern Plan"
- [ ] Three subscriptions with the exact product IDs, ranks and prices
- [ ] Family Sharing on, 7-day free introductory offer on each
- [ ] Localizations (en-US) for the group and each product
- [ ] Paid Apps agreement active
- [ ] Sandbox tester created

## Submission (November 4, 2026)

- Build 5 (25186fc0-ff8c-4469-b123-e0e077ac1fe0) and build 6 (0339f725-b591-49ac-8983-82ef3ad495c7) uploaded and processed.
- Version 1.0 (28f15ab6-977f-4450-b665-ed21d71fe85c) attached to build 6.
- App Privacy published in the web UI ("we do not collect data").
- Review submission 17f5f2bc-df13-4efa-a88c-ac3b7df5d20f: version item added, submitted=true → WAITING_FOR_REVIEW.
- Internal TestFlight group "Kismet internal" receives every build automatically.

## Resubmission (November 4, 2026, 04:50 UTC)

- First submission 17f5f2bc cancelled (PATCH canceled=true); version went DEVELOPER_REJECTED, which
  unlocks screenshots.
- Deleted 08-paywall.png (showed prices) and the old 01-home.png; uploaded a new 01-home.png of the
  dashboard captured with `-demo -tab Home -plan family6` (no trial banner). Eight screenshots, reordered.
- New review submission 27817508-257f-4715-a9a7-7fcd7a726ce8 with the version item, submitted → WAITING_FOR_REVIEW.

## Third submission, with the subscriptions (November 4, 2026, 18:05 UTC)

- Both earlier submissions held only the version item. Family 6 and Family 10 stayed READY_TO_SUBMIT
  ("Prepare for Submission" in the UI), which is the CastleWise 2.1(b) gap: the app would have shipped
  with subscriptions that are not approved. The API cannot fix it. `reviewSubmissionItems` has no
  `subscription`, `inAppPurchaseV2` or `subscriptionGroup` relationship (all three return
  "unknown relationship"), so the subscriptions have to be attached in the web UI.
- Done in a Chrome launched with a remote-debugging port, driven with a 60-line CDP script
  (`~/.appstoreconnect/browser/cdp.js`: `goto`, `shot`, `eval`, `click`, `type`). The React rows need
  real mouse events (Input.dispatchMouseEvent); element `.click()` does nothing.
- Steps: cancel 27817508 (PATCH canceled=true), version → DEVELOPER_REJECTED. On the version page click
  "Add for Review": a Draft Submission appears with iOS App 1.0. On the subscription group page
  (`/distribution/subscription-groups/22542888`) "Add for Review" is a dropdown: pick "Draft iOS
  Submission". The draft then says "Unable to Submit: new subscription groups must be submitted with an
  auto-renewable subscription from within that group." On each subscription page
  (`/distribution/subscriptions/6830418767`, `/6830418569`) the same dropdown → the draft. Group 50 left
  out. "Submit for Review" → "4 Items Submitted".
- Quirk: after a page navigation the first mouse click on "Add for Review" only focuses the page; the
  second opens the menu (`aria-expanded` goes true).
- Result: review submission f28461ea-3ecc-4d41-b9a9-6e96910294ed, WAITING_FOR_REVIEW, 4 items (version,
  group, Family 6, Family 10), all READY_FOR_REVIEW. Family 6 and Family 10 are WAITING_FOR_REVIEW,
  Group 50 stays READY_TO_SUBMIT, version 1.0 WAITING_FOR_REVIEW.
- Cost: the queue position from 04:50 UTC. Submitted again at 18:05 UTC.

## 1.0.1, build 7 (November 4, 2026, 18:32 UTC)

- Uploaded to TestFlight while 1.0 (build 6) sits in review. A new version's build does not touch the
  review. Delivery ceaa2295-f9ea-471a-a62c-efc8dcead444. The internal group receives it automatically.
- What's in it: the games section built out (twenty games) and ready-to-send status texts. See plan.md §22.
- Do not attach build 7 to version 1.0. When 1.0 is approved and released, create version 1.0.1 in App
  Store Connect, attach build 7 (or a later one), and submit.

## Duo subscription (November 4, 2026)

- Created through the API: id 6830816212, product io.kismetstudio.lantern.duo, group level 4, one year,
  Family Sharing on, en-US "Duo" / "Two people in your house, unlimited supplies.", available in every
  territory with a 7-day free trial in each. USA $7.99 with the other territories from the equalizations.
- Order that works: create, localization, availability, then prices (a price POST before availability
  returns UNSUPPORTED_TERRITORY), then intro offers.
- State: Ready to Submit. Goes into the 1.0.1 submission by hand (web UI, Add for Review) with the build.
- The last missing piece of metadata was the App Store review screenshot (Family 6 and Family 10 had one
  from the first pass). Uploaded the paywall capture (`-plan free -screenshot paywall`, which shows Duo
  selected) through `subscriptionAppStoreReviewScreenshots`: reserve, PUT the bytes to the upload
  operations, PATCH uploaded with the MD5. Script: `~/.appstoreconnect/lantern_duo_shot.py`.
