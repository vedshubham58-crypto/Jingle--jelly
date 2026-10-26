# Jingle Jelly

A toddler app (ages 1-4) for Android: sing-along nursery rhymes, Bath Time and
Bubble Pop with Jelly, a wobbly jelly friend. Made with Godot 4.3.

- `godot/` the game. Everything is drawn in code (`scripts/draw.gd`, `scripts/jelly.gd`).
- `godot/data/songs.json` the songs: public-domain rhymes, notes and words.
- `tools/make_audio.py` makes all music and sound effects into `godot/audio/`
  (`python3 tools/make_audio.py`, needs numpy and ffmpeg). No outside recordings.
- `android-ads-plugin/` a small Godot plugin for kid-safe AdMob interstitials.
- `.github/workflows/build.yml` tests the game and builds the APK on every push.
  Pushes to `main` publish it at
  `https://github.com/<owner>/jingle-jelly/releases/download/test-build/jingle-jelly.apk`.

## Kids rules (Google Play Families policy, COPPA)

- Every ad request is child-directed, under the age of consent and G rated, so ads
  are never personalised. The advertising ID permission is removed, and CI fails
  the build if it ever comes back.
- Ads only show between activities (at most every 3rd finished activity, 2 minutes
  apart), never during play.
- Settings sit behind a parent gate (numbers written as words).
- No personal data is collected; progress is saved only on the phone.
- Spoken prompts use the phone's own text-to-speech voice, offline.

## Before launch

- Replace Google's test ad ids in `godot/scripts/ads.gd` and
  `godot/addons/jelly_ads/plugin.gd` with real AdMob ids (mark the app as
  "directed to children" in AdMob too).
- Add a release signing key and a privacy policy page.
- Fonts: Baloo 2, SIL Open Font License (`godot/fonts/OFL.txt`).
