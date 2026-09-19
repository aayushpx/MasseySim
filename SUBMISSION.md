# Submission notes (itch.io / MUITSA Game Making Hackathon 2026)

## What to upload

Recommended: one zip with everything, or three separate uploads. itch.io lets
you mark one as the "primary" file you want the Play button to launch.

| Upload | Contents | Use |
|---|---|---|
| `massey-uni-simulator-web.zip` | everything inside `builds/web/` | itch.io **Web** upload → instant play in-browser |
| `massey-uni-simulator-linux.zip` | `builds/linux/` (both files) | Desktop download |
| `massey-uni-simulator-windows.zip` | `builds/windows/` (both files) | Desktop download |

Ship the `.pck` files alongside their executables (they are **not** embedded).

## Making the zips

```sh
cd builds
zip -r ../massey-uni-simulator-web.zip      web
zip -r ../massey-uni-simulator-linux.zip    linux
zip -r ../massey-uni-simulator-windows.zip  windows
```

## itch.io metadata (suggested)

- **Kind**: HTML (make the web bundle the playable upload; add the desktop
  zips as additional files)
- **Embed options**: `hide_ui` on-ish, 1280x720, optionally
  `max_scale=1.35` — stretch mode is `canvas_items/aspect=expand` so it
  letterboxes gracefully at any window size.
- **Genre**: Simulation / Student-life comedy
- **Tags**: university, parody, massey, time-management, hackathon
- **Controls blurb** (paste into the page):
  > WASD/Arrows to move, E/Space to talk to zones, 1-4 to answer quizzes.
- **Credit line** for the page footer / credits field:
  > Art: original. Fonts: Fraunces & Work Sans (SIL OFL). Music: Kevin
  > MacLeod (incompetech.com), CC-BY 4.0. SFX: Kenney.nl, CC0.
  > A fan parody; not affiliated with Massey University or MUITSA.

## Web + audio gotcha

The exported web build starts audio on user input (browser autoplay rules).
The first button press primes it — this is normal.

## Release checklist

- [ ] All scenes run clean headless (see README "Running it").
- [ ] `flow_test`, `campus_smoke`, `sim_test` pass.
- [ ] Balance numbers untouched from the signed-off version.
- [ ] ASSETS.md lists source URL + licence for every external asset.
- [ ] Builds re-exported from the final commit.
- [ ] itch.io page includes the Kevin MacLeod CC-BY attribution.