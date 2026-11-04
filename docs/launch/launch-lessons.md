# Lantern launch: everything we learn

Running notes, started November 4, 2026, the day 1.0 went into review. Raw material for the eventual
post on launching a second solo iOS app with the lessons from the first one applied. Rules for that post:
numbers over adjectives, say what failed, no em dashes, nothing about Tim's day job or employer anywhere.

## 0. What CastleWise taught, and what Lantern did about it

CastleWise's launch-lessons.md listed eleven things it would do differently. Here is where Lantern stands
on each, before launch:

1. **W-9, Paid Apps agreement and Small Business Program before the first submission.** Open. Check
   Business, Agreements tonight. Enroll in the Small Business Program the day Paid Apps reads Active.
2. **Privacy label correct from day one.** Done. "Data Not Collected" is true: no analytics, no account,
   barcode digits only. Published before submission, and the submission would not go through until it was.
3. **Screenshots at the current size, no price anywhere.** Half done. Size is right (1320 x 2868). The
   paywall screenshot shows $12.99. Decision in punch-list.md.
4. **Beta tester list with emails, codes and copy ready a week out.** Copy is ready (beta-tester-thankyou.txt).
   Codes are offer codes, not promo codes, because the plan is a subscription. Request them tonight.
5. **Apple Ads drafted, built on release morning, brand campaign at $1 forever.** Drafted
   (apple-ads-keywords.md).
6. **Reddit campaigns scheduled before launch week.** Build sheet written (reddit-build-sheet.txt). It is
   scheduled for Day 15 on purpose: promote a post that already earned upvotes.
7. **Analytics sink deployed before launch.** Deliberately none. Lantern's privacy promise is no analytics,
   and the store label says so. The cost is that "where do people hit the paywall" has to come from
   reviews and testers. Accepted.
8. **Direct App Store link everywhere; nothing says "search for it".** Done in every file in this kit.
   The direct link resolved minutes after CastleWise's release; search took 30 hours.
9. **Attach the IAP to the version; confirm "Items Submitted" before submitting.** Nearly missed again.
   The API submission takes only the version; the subscriptions stayed "Prepare for Submission" through
   two submissions. Fixed the third time by adding the group and both subscriptions to the draft in the
   web UI: "4 Items Submitted". The rule for next time: the submission is not done until the sheet says
   the IAP count, and the API cannot do that part. See app-store-connect.md.
10. **A released version cannot take a new build; plan version numbers assuming 1.0 is final.** The next
    build goes to 1.0.1, not 1.0.
11. **Only build from one copy of the project.** The Mac copy is the only one that archives. The container
    copy only edits and pushes.

Two new ones Lantern added:

- **The command center takes a launch date.** CastleWise's was written for a fixed Tuesday and every slip
  meant editing the file. Lantern's computes every day from one date field.
- **The coming-soon post said "no subscription".** Written before pricing was decided, posted the night of
  the Florida flooding. Nothing public says it from here on. Lesson: no promises about money in a teaser.

## 1. Before you submit (Lantern's own)

- App Privacy cannot be published through the API and the submission is refused until it is. It is the
  last click and it has to be a person. Budget a day for it.
- Subscription "MISSING_METADATA" with no detail means one of 175 territories has no price. The
  equalizations endpoint fills them all from the base price in one call per subscription.
- Introductory offers need a territory relationship each. One call per territory, 175 per subscription.
- Group 50's description was over the 55-character limit for a subscription display name. Shorter.
- The App Store Connect API cannot create the app record (web only) and cannot add an internal tester
  (web only). Everything else scripted.
- Build 5 was uploaded for a one-line search fix and build 6 followed four hours later with the
  dashboard. Should have waited and shipped one. Processing time was about seven minutes each.

## 2. Beta testers

- Nine testers, all family and friends, about two weeks of TestFlight before submission.
- Feedback that shipped: select-to-delete in Supplies, "+" on each location, per-kind equipment questions,
  the invitation steps and household code, nutrition facts on food, the dashboard, the fuller profiles.
  All of it came from one person's screenshots with one sentence each. Screenshots beat descriptions.

## 3. Launch day and launch week

(to be written)

## 4. Apple Ads

(to be written)

## 5. Reddit

(to be written)

## 6. The store page

- The keyword field at submission: emergency, preparedness, hurricane, outage, pantry, expiration, go bag,
  medication, family, storm, prepper. 92 characters. Apple indexes words, not phrases, and composes phrases
  across title, subtitle and keywords. "Household" and "readiness" are in the title and so are free.
  Candidates for 1.0.1: tracker, inventory, water, generator, checklist, kit, food, supplies (dropping
  "prepper" if it brings the wrong searches).

## 7. Pricing

See pricing-plan.md. Nothing decided until 100 downloads and 30 days.

## Log

- 2026-11-04, 18:05 UTC: third submission. The first two carried only the version; Family 6 and Family 10
  were never in them. The API has no way to add a subscription to a review submission, so it was done
  in the web UI through a scripted Chrome: group, then each subscription, "Add for Review" → the draft,
  then Submit. Submission f28461ea, 4 items. Lesson: the API path is not the whole path. Count the items
  on the sheet before clicking Submit; the number must be 1 + the IAPs.

- 2026-11-04: 1.0 (build 6) submitted. App Privacy was the last blocker and took a person. Launch kit
  written. Screenshot 8 showed a price; the submission was pulled an hour later, the screenshot deleted,
  Home reshot as the dashboard, and 1.0 resubmitted. Lesson: cancelling a submission through the API puts
  the version in DEVELOPER_REJECTED, which is what unlocks screenshots; a new submission with the version
  item goes straight back to Waiting for Review. Whole round trip about ten minutes of work.
