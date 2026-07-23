# Minimal LCD — Garmin Venu 3 Watch Face

A minimalist digital watch face for the Garmin Venu 3 / Venu 3S, styled after
classic segmented-LCD digital watches (black background, white text).

## Layout

- **Top-left**: a live compass needle (rotates to point at magnetic north as
  you turn your wrist).
- **Top row**: day of week + date, shown as `DAY DD-MM` (e.g. `THU 23-07`).
- **Center**: large 24-hour time, `HH:MM`.
- **Bottom row**: battery icon + percentage (left), steps icon + step count
  (right).

All text/digits are drawn as classic 7-segment LCD glyphs using plain filled
rectangles (see `source/SevenSegment.mc`) rather than a bitmap font — this
avoids any font-licensing issues and renders crisply at any size.

## Project layout

```
manifest.xml                        App manifest (targets venu3 + venu3s)
monkey.jungle                        Build config
resources/strings/strings.xml        App name
resources/drawables/drawables.xml    Launcher icon reference
resources/drawables/launcher_icon.png
source/WatchFaceApp.mc                App entry point
source/WatchFaceView.mc               Drawing logic (layout, compass, icons)
source/SevenSegment.mc                7-segment digit/colon/dash renderer
```

## Building

You'll need the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
and a developer key. Easiest path is the **Monkey C extension for VS Code**:

1. Install the "Monkey C" extension in VS Code.
2. Run **Monkey C: Configure SDK** and point it at a downloaded SDK.
3. Run **Monkey C: Generate a Developer Key** (one-time).
4. Open this folder in VS Code, then **Monkey C: Build for Device** (or
   press F5 to build + run in the simulator), selecting `venu3` or `venu3s`.

Or from the command line, once the SDK's `bin/` is on your `PATH`:

```sh
monkeyc -d venu3 -f monkey.jungle -o bin/MinimalLCD.prg -y developer_key.der
monkeydo bin/MinimalLCD.prg venu3   # run in the simulator
```

To install on your actual Venu 3: connect it over USB, then copy the built
`.prg` into the watch's `GARMIN/APPS` folder (or use VS Code's "Build for
Device" which does this for you), then eject and reboot the watch face menu.

## Known platform limitation: the compass needle

Garmin throttles magnetometer (compass) polling on watch faces to save
battery — you don't get a free-running real-time feed the way an activity
app would. In practice:

- While you're actively looking at the watch (screen lit), the heading
  updates roughly once a second, so the needle tracks your wrist turning in
  near real time.
- Once the screen times out / goes to ambient, the system stops delivering
  updates (this face doesn't use always-on display anyway, per your spec).

The code already follows Garmin's recommended pattern for this — sensor
events are enabled in `onShow()` and disabled in `onHide()` — so you get the
best update rate the platform allows without needlessly draining battery
when the face isn't visible. Until the first sensor reading arrives (e.g.
right after the face loads), the needle simply points straight up as a
placeholder.

## Customizing

- Colors: change the `Gfx.COLOR_WHITE` / `Gfx.COLOR_BLACK` references in
  `WatchFaceView.mc` (e.g. add an accent color for the compass or bottom
  row).
- Sizing: every element is positioned as a fraction of screen width/height,
  so it automatically scales between the Venu 3 (454×454) and Venu 3S
  (390×390) — tweak the fraction constants in each `draw*` function to
  adjust proportions.
- Date order: currently day/month (`DD-MM`); swap the token order in
  `drawDayDate()` in `WatchFaceView.mc` if you ever want month/day instead.
