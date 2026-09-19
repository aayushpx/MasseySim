# Massey Uni Simulator

A short, funny, top-down game about surviving as a Massey University student —
built for the MUITSA Game Making Hackathon 2026.

**Survive 7 days. Don't drop out. Try to graduate.**

- Pick one of four degrees (same game under the hood, different jokes).
- Walk a flat-vector campus: Lecture Hall, The Spiral Library, Food Hall,
  Dorm Flat, the MUITSA Clubroom and the Exam Hall.
- Balance **Energy**, **Stress** and **GPA** across 3 slots a day.
- Survive pop quizzes, assignments, geese, and one very skippable exam.
- Fan-made parody — all branding is original/parody dressing on Massey's
  public colour palette. No real Massey logo or crest is used.

## Controls

| Key | Action |
|---|---|
| WASD / Arrow keys | Move |
| E / Space | Interact with a zone (pop up actions) |
| 1-4 | Answer a quiz question |
| Mouse | Everything else (buttons) |

## How to play

Each day has **Morning / Afternoon / Evening** slots. Talk to a zone and pick
an action. Studying raises GPA but costs Energy and Stress; eating and napping
refill you; the clubroom chills you out. Do your assignments before they go
late, dodge the geese on your way to class, and sit the **Finals on Day 7**.

Win: GPA **>= 55** after Finals.
Lose: Energy hits 0, Stress hits 100, GPA drops below 40, or you skip Finals.

## Running it

**Editor / playtest** (requires Godot 4.7.x):

```
godot --path . -e        # open editor (press F5 to run)
godot --path .           # run directly
```

**Exported builds** are in `builds/`:

| Platform | Location |
|---|---|
| Linux (x86_64) | `builds/linux/massey-uni-simulator.x86_64` |
| Windows (x86_64) | `builds/windows/massey-uni-simulator.exe` |
| Web (shared bundle) | `builds/web/index.html` |

Serve the web folder over HTTP (it needs a server; the .wasm won't run from
`file://`):

```
python3 -m http.server --directory builds/web 8000   # http://localhost:8000
```

## Rebuilding

```
godot --headless --export-release "Linux"   builds/linux/massey-uni-simulator.x86_64
godot --headless --export-release "Windows" builds/windows/massey-uni-simulator.exe
godot --headless --export-release "Web"     builds/web/index.html
```

Headless tests (fast, no window):

```
godot --headless res://tests/flow_test.tscn --quit-after 40
godot --headless res://tests/campus_smoke.tscn --quit-after 40
godot --headless res://tests/sim_test.tscn --quit-after 60
```

## Project layout

```
autoloads/game_state.gd  Game rules, day/slot loop, events, balance constants
autoloads/audio.gd       AudioFx - pooled SFX + crossfading music
scenes/                  main menu, degree select, campus, 3 minigames, win/lose
scripts/                 gameplay + the flat-vector art/UiKit/Palette libraries
assets/fonts/            Fraunces + Work Sans (SIL OFL 1.1)
assets/audio/            music + SFX (CC-BY / CC0 - see ASSETS.md)
assets/shaders/          ground glow + vignette
DESIGN.md                design doc, palette, balance, allowed-use notes
ASSETS.md                every external asset, source URL + licence
```

## Credits & licences

- **All art**: original flat-vector art drawn natively in Godot (no image
  assets licensed or vendored).
- **Fonts**: Fraunces & Work Sans by Google Fonts, SIL Open Font License 1.1.
- **Music**: Kevin MacLeod (incompetech.com) — *Carefree*, *The Builder*,
  *Clean Soul*, CC BY 4.0. https://incompetech.com
- **SFX**: Kenney (kenney.nl) — Interface Sounds & UI Audio, CC0.
- Full source/URL/licence table in [`ASSETS.md`](ASSETS.md).

Tile, character and colour usage follows Massey's public brand palette;
MUITSA colours are an original pick (no official MUITSA hex published).

*Massey Uni Simulator is an unofficial fan game and is not endorsed by or
affiliated with Massey University or MUITSA.*