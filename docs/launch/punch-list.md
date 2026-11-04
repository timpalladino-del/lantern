# Punch list before release

In order. The first two are decisions; the rest are chores.

## 1. The paywall screenshot showed a price (done, November 4)

Screenshot 8 showed "$12.99 per year" and "Start 7-day free trial", the CastleWise 2.3.7 rejection. The
submission was pulled, that screenshot deleted, the stale Home screenshot replaced with the new dashboard
(captured with the Family plan active so no trial banner shows), and 1.0 resubmitted with eight
screenshots. New review submission 27817508-257f-4715-a9a7-7fcd7a726ce8, Waiting for Review again at
04:50 UTC. Then cancelled a third time at 18:05 UTC to add the subscriptions (they were never in the
first two). Submission f28461ea, 4 items. Cost: the day's queue position, twice.

## 2. The coming-soon post said "no subscription"

The November 3 Facebook post and the coming-soon images say "No account. No cloud. No subscription."
Lantern has subscriptions. Nothing public from here on says "no subscription". The launch images in
social/ say "No account. No cloud. Toolkit free for everyone." If anyone quotes the old line back, the
honest answer is: the toolkit is free for everyone with no subscription, and that promise stands; the
family tracking is what the plan pays for.

## 3. App Store Connect pre-flight (tonight)

- Business, Agreements: Paid Apps must read Active. Without it the subscription fails silently on launch
  day and you find out from a stranger.
- Tax forms: W-9 on file. A missing one stalled a CastleWise review for weeks.
- Small Business Program: enroll the day Paid Apps goes Active. 85 percent instead of 70, and it is not
  retroactive.
- Distribution, 1.0: confirm Manually release this version (it is set; glance at it).
- Monetization, Subscriptions: Family 6 and Family 10 read Waiting for Review since 18:05 UTC (third
  submission, f28461ea, 4 items). They must read Approved after review, with the 7-day trial attached in
  all territories. Group 50 is in the group but not on the paywall; leave it.
- Offer codes for Family 6: one-time use, free, 1 year, 100 codes. See beta-tester-thankyou.txt.

## 4. Site swap, ready to flip (tonight)

The live version of kismetstudio.io/lantern/ is on branch `lantern-live` of the site repo: badge above
the fold, "Coming soon" badge gone, the notify section replaced with the download block. Merge it to
main on release morning after the trial test passes. The press page is already live at
/lantern/press/ because nothing on it depends on release.

## 5. Reddit warm-up (tonight and tomorrow)

Join: r/homeowners, r/firsttimehomebuyer, r/HomeMaintenance, r/Parenting, r/CaregiverSupport, r/Frugal,
r/florida, r/SideProject, r/iosapps, r/iOSProgramming, r/AppHookup. Five helpful comments tonight, three
tomorrow, zero mentions of the app. A new account posting a link on launch day is removed on sight.

## 6. Reddit Ads built and Scheduled (tonight)

reddit-build-sheet.txt, every field. iOS only is the setting that cannot be changed after save.

## 7. Beta tester list (tomorrow)

Name, phone or email, one offer code each, a column for sent and a column for redeemed. Nine testers. The
heads-up goes out release morning before anything else.

## 8. The launch date in the command center (whenever you know it)

Open lantern-launch-command-center.html, set the date at the top. Every day in the plan and the Tracker
takes its real date. Then run `python3 tools/make_ics.py --launch YYYY-MM-DD` and import the .ics so the
readouts and the Reddit start are on your calendar.

## Known and accepted for 1.0

- The App Store link in family invitations only works once the app is live. Testers already have it.
- `-demo` screenshot data does not include the new profile fields on all people; fine for the store.
- The Group 50 plan exists in App Store Connect but is hidden in the app. Nothing to do.
