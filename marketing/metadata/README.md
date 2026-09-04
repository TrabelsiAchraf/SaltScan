# App Store metadata (version 0.4.0)

One folder per App Store Connect localization, one file per field, ready to paste.
File names follow the fastlane `deliver` convention so the folder can be uploaded
with `fastlane deliver --metadata_path marketing/metadata` later.

| Locale | Name | Subtitle | Keywords |
|---|---|---|---|
| `en-US` | Salt Scan: Sodium Tracker (25) | Food scanner & daily intake (27) | 97/100 |
| `en-CA` | Salt Scan: Sodium Tracker (25) | Food scanner & daily intake (27) | 97/100 |
| `en-GB` | Salt Scan: Salt Intake Tracker (30) | Food scanner & traffic lights (29) | 100/100 |
| `en-AU` | Salt Scan: Salt Intake Tracker (30) | Food barcode scanner & checker (30) | 100/100 |
| `fr-FR` | Salt Scan : Sel & Sodium (24) | Scanner alimentaire & tension (29) | 99/100 |
| `fr-CA` | Salt Scan : Suivi du sodium (27) | Scanner aliments, sel & santé (29) | 98/100 |
| `ar-SA` | Salt Scan: ماسح الملح (21) | تتبع الصوديوم وضغط الدم (23) | 74/100 |

Storefronts and what they index (AppTweak, Nov. 2025): US reads en-US plus fr-FR and
ar-SA (bonus); GB reads en-GB (+ en-AU); FR reads fr-FR (+ en-GB); CA reads en-CA
(+ fr-CA); AU reads en-AU (+ en-GB); SA reads ar-SA (+ en-GB); BE reads en-GB
(+ fr-FR, nl-NL). en-US is indexed nowhere else than the US, hence the separate
en-GB / en-CA / en-AU localizations.

## Rules baked into these files

- Apple counts each word once across name, subtitle and keywords of a locale: no
  word is repeated between the three fields.
- Limits: name 30, subtitle 30, keywords 100 (comma separated, no spaces),
  promotional text 170, description and release notes 4000.
- The brand stays "Salt Scan" everywhere; only the suffix changes with the market
  vocabulary (sodium for US/CA, salt for GB/AU, sel for FR, Arabic for SA).
- `promotional_text.txt` can be changed on the live version without a release.
  Everything else ships with the next version.

## Checklist in App Store Connect

1. App Information › Localizations: add en-GB, en-CA, en-AU, fr-CA, ar-SA
   (en-US and fr-FR already exist). Paste `name.txt` and `subtitle.txt`.
2. Version 0.4.0 › each localization: paste `description.txt`, `keywords.txt`,
   `promotional_text.txt`, `release_notes.txt`.
3. Screenshots: upload `marketing/screenshots/<locale>/6.9/slide_1..6.png` to the
   iPhone 6.9" set, `.../6.5/` to the 6.5" set and `.../ipad-13/` (2064 × 2752) to
   the iPad 13" set. en-CA uses en-US, en-AU uses en-GB, fr-CA uses fr-FR.
4. App Privacy: AdMob and Firebase Analytics are gone in 0.4.0. The only remaining
   third parties are Open Food Facts (product lookups) and the Firestore fallback,
   neither of which collects user data for the developer, so "Data Not Collected"
   is accurate. Re-check the label if an SDK is ever added back.
5. Nothing to configure in any ad console anymore.
6. After release: watch App Store Connect › Analytics (impressions, product page
   views, conversion rate) per territory and per source, against the pre-release
   baseline.
