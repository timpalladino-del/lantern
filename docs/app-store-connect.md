# App Store Connect setup for Lantern

Everything the paywall expects, so the products can be created in one sitting. The IDs must match exactly;
they are hard-coded in `Lantern/Services/PlanStore.swift` and mirrored in `Config/Lantern.storekit`.

## App record

- Bundle ID: `io.kismetstudio.lantern` (team 69MM5TC2UN)
- Name: Lantern
- Subtitle: Ready for when you need it most.
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

## Checklist

- [ ] App record created with the bundle ID above
- [ ] Privacy policy and terms URLs entered
- [ ] Subscription group "Lantern Plan"
- [ ] Three subscriptions with the exact product IDs, ranks and prices
- [ ] Family Sharing on, 7-day free introductory offer on each
- [ ] Localizations (en-US) for the group and each product
- [ ] Paid Apps agreement active
- [ ] Sandbox tester created
