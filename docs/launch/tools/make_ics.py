#!/usr/bin/env python3
"""Calendar file for the 30-day plan, from a launch date.

    python3 make_ics.py --launch 2026-11-10 > ../lantern-dates.ics

Every event is an all-day entry on the right day with the task in the description, plus the two readouts
a week (Tuesday and Friday). Import into Calendar on the Mac or the iPhone.
"""
import argparse
import datetime as dt
import uuid

EVENTS = [
    (0, "Day 1 · Release morning", "8:00 press Release This Version. Confirm live via the direct link, start a real Family trial on your own phone, TestFlight install test on a tester's phone, send the heads-up then the thank-you with codes, build both Apple Ads campaigns (Brand on now, Core paused), post r/SideProject, post Facebook with link in first comment, swap the site to the live badge."),
    (1, "Day 2", "r/iosapps build story. 8 to 10 Messenger notes one to one. Three helpful comments in home subs, no mentions."),
    (2, "Day 3 · Ads on", "Create campaign links in App Analytics if the + button is there: fb-launch, fb-post, reddit-maker, reddit-home, reddit-ads, web. Turn on Exact Match Core. r/iOSProgramming post. First readout tonight."),
    (3, "Day 4", "Rating ask to beta testers (separate message). Replies on every review."),
    (4, "Day 5", "r/apple weekly thread, two lines. Facebook post 3."),
    (5, "Day 6 · Saturday", "r/homeowners pantry audit post, no link. Facebook post 4."),
    (7, "Day 8", "r/Parenting medication card post, no link. Facebook post 5. First trial cohort clears its 7 days: read trial-to-paid."),
    (9, "Day 10", "Custom product page 'Outage first'. Point Apple Ads group A at it. Facebook post 6."),
    (11, "Day 12", "r/firsttimehomebuyer first-week photo list, no link. Facebook post 7."),
    (12, "Day 13 · Saturday", "Facebook post 8."),
    (14, "Day 15 · Reddit Ads start", "By 8 PM confirm Spend is above $0 on ads.reddit.com. Facebook post 9."),
    (15, "Day 16", "r/AppHookup giveaway, 25 codes. Discovery campaign in Apple Ads, $2 a day, Search Match on."),
    (16, "Day 17", "Facebook post 10."),
    (17, "Day 18", "Reddit readout: cost per click by creative. Modmail r/CaregiverSupport about the medication thread."),
    (18, "Day 19", "r/CaregiverSupport post. Second rating ask on Facebook (to the new downloaders only)."),
    (19, "Day 20 · Saturday", "Facebook post 12. Add one Reddit challenger only if A1 is under 1.2 percent CTR."),
    (21, "Day 22 · Reserve decision", "Readout. Move the $50 reserve to whichever channel is under $2.50 a download. Harvest Discovery terms into Core and add them as negatives in Discovery."),
    (23, "Day 24 · Reddit Ads end", "Export the Reddit numbers while you can still find them."),
    (25, "Day 26", "Facebook post 15 (seasonal)."),
    (26, "Day 27 · Saturday", "Facebook post 16."),
    (27, "Day 28", "In-App Event: 'Winter outage weekend' or 'Hurricane season wrap-up', whichever fits the date. Free placement."),
    (29, "Day 30 · Scorecard", "Fill the Day 30 card in the Tracker. Three sentences: what worked, what did not, what wasted the most time. Decide the 1.0.1 keyword field."),
]


def ics(launch: dt.date) -> str:
    out = [
        "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Kismet Studio//Lantern launch//EN", "CALSCALE:GREGORIAN",
        "X-WR-CALNAME:Lantern launch",
    ]
    stamp = dt.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")

    def add(day, title, desc):
        d = launch + dt.timedelta(days=day)
        out.extend([
            "BEGIN:VEVENT", f"UID:{uuid.uuid4()}@kismetstudio.io", f"DTSTAMP:{stamp}",
            f"DTSTART;VALUE=DATE:{d:%Y%m%d}", f"DTEND;VALUE=DATE:{d + dt.timedelta(days=1):%Y%m%d}",
            f"SUMMARY:Lantern · {title}", "DESCRIPTION:" + desc.replace(",", "\\,").replace(";", "\\;"),
            "END:VEVENT",
        ])

    for day, title, desc in EVENTS:
        add(day, title, desc)
    # Tuesday and Friday readouts for 30 days
    for i in range(1, 31):
        d = launch + dt.timedelta(days=i)
        if d.weekday() in (1, 4):
            add(i, f"Readout (Day {i + 1})", "Ten minutes: downloads, page views, ratings, trial starts, trial-to-paid, ads spend and cost per install. Write them in the Tracker tab, then apply the three mechanical rules.")
    out.append("END:VCALENDAR")
    return "\r\n".join(out) + "\r\n"


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--launch", required=True, help="YYYY-MM-DD, the morning you press Release")
    a = ap.parse_args()
    print(ics(dt.date.fromisoformat(a.launch)), end="")
