# Massey Uni Simulator — Game Design Doc

> Working title: **"Massey Uni Simulator"**

## Pitch

You are a first-year student at an affectionately-parodied version of Massey University's
Manawatū campus. Your only goal: survive 7 hilarious in-game days until Graduation Day
without running out of Energy, maxing out Stress, or letting your GPA tank. Walk your
little round character around a stylised campus hub, spend each day's 3 action slots
wisely between lectures, library study, cafeteria refuels, flat naps and a MUITSA club
night, and survive the surprise events uni throws at you: pop quizzes, essay deadlines, a
frenzied rush to class dodging campus geese, and the final boss — Finals Week. Short,
laugh-out-loud, winnable in one focused 3–5 minute run, replayable for a better grade and
better jokes.

## Core loop (text diagram)

```
        ┌─────────────────────────────────────────────┐
        │                                             │
        │      Main Menu → Start Run (Day 1)          │
        │              │                              │
        │              v                              │
        │   ┌─── Campus Hub: walk to a ZONE ────┐     │
        │   │  Press E on zone for its ACTIVITY  │     │
        │   └────────────┬───────────────┬───────┘     │
        │                v               │             │
        │   Wait / Prompt if special     │  Meters update
        │   (quiz, essay, geese, exam)   │  (Energy/Stress/GPA)
        │                │               │             │
        │                └────► 3 slots used? ──► Night: auto-sleep + daily drift
        │                                    │        │
        │                                    v        │
        │                          Day 7 + exam passed? ─► Graduation (WIN)
        │                                    │        │
        │                          Any meter out of range? ─► Dropped Out (LOSE)
        └─────────────────────────────────────────────┘
```

## Win / Lose conditions (explicit, Balance Pass 1 — will tune in playtest)

| Meter    | Start | Bad below | Lose rule                |
|----------|-------|-----------|--------------------------|
| Energy   | 70/100 | 0        | 0 → collapsed, "Dropped Out" |
| Stress   | 30/100 | 100 (max)| 100 → burnout, "Dropped Out" |
| GPA      | 60/100 | 40       | < 40 → academic suspension |

**WIN:** Survive the exam at end of **Day 7** with final **GPA ≥ 55** → Graduation scene.

**RUN LENGTH:** 7 days × 3 action slots = 21 actions; exams take the Day 7 slot.

### Time & passives (night auto-sleep after each 3-slot day)
- Energy: +25 after sleep, −5 overnight drift (must eat to stay ahead)
- Stress: −5 after sleep, +2 daily grind
- GPA: −3 overnight (course content compouds/you forget stuff — keeps GPA pressurised)

### Zone activities (each costs 1 slot)
| Zone | Activity (press E) | Energy | Stress | GPA | Notes |
|------|--------------------|--------|--------|-----|-------|
| Lecture Hall | Attend lecture | −8 | +7 | +5 | Morning/Afternoon only. Can trigger Pop Quiz |
| Library ("The Spiral") | Study | −9 | +8 | +8 | Any slot |
| Library | Work on assignment | −4 | +5 | +8 | Only on the day it's due (else it's late!) |
| Cafeteria ("Food Hall") | Eat + memes | +20 | −10 | 0 | Any slot |
| Flat (Dorm) | Nap | +28 | −4 | 0 | Any slot (no, you can't nap your degree) |
| **MUITSA Clubroom** | Chill at club night | −3 | −12 | 0 | Stress-relief side of campus |
| **MUITSA Clubroom** | MUITSA Quiz Night | −2 | −8 | +3 | **Day 6 evening special** — reuses MCQ engine, club-flavoured questions |
| Exam Hall | Finals | +6 stress | +0–12 | Only on Day 7, after exam sim |

> Values shown are ticks on a 0–100 scale. Exact tuning happens in the playtest pass.

### Timed events (deterministic, not random — fair & beatable)
- **Day 2 & Day 4 lecture = POP QUIZ** minigame: 3 multiple-choice questions, timed.
  Correct answers = +GPA (up to +12) + a little stress. It's a mini "reaction-time trivia."
- **Day 3 morning = RUSH TO CLASS** minigame: dodge campus geese across the quad
  before the bell. Hit geese = +stress; arriving fast = +"on-time" GPA bonus.
- **Assignments due Day 3, 5, 6**: visit the Library that day & "finish the essay
  before the wifi drops" (timed key-press reaction minigame). Completing = +8 GPA.
  Missing the day = −10 GPA the next morning (a "late penalty" popup you only see
  once, so it doesn't feel like a gotcha).
- **Day 6 evening = MUITSA QUIZ NIGHT**: an optional after-hours club event; silly
  IT-student trivia, small GPA + stress relief. A taste of the society pre-finals.
- **Day 7 = FINALS (Boss)**: multi-wave multiple-choice exam with a shrinking answer
  timer. Fewer correct = smaller GPA bump; flunk it but keep overall GPA ≥ 55 and you
  still squeak into graduation — hard but not save-scumming unfair.

## Scenes / screens
1. `main_menu.tscn` — title, "Start Semester", controls, best-grade memory (optional)
2. `campus.tscn` — top-down hub + HUD (Energy / Stress / GPA bars, day counter, slot dots)
3. `pop_quiz.tscn` — MCQ minigame overlay (full scene swap for simplicity)
4. `rush_to_class.tscn` — dodge-minigame scene
5. `essay_sprint.tscn` — "finish assignment" reaction minigame
6. `exam.tscn` — finals boss
7. `win.tscn` — Graduation: confetti, joke speech, Play Again
8. `lose.tscn` — "Dropped Out" with reason + Retry
9. (optional) `clubroom` scene area — built into campus.tscn as a zone, not separate

## Controls
- **WASD / arrows** move, **E / Space** interact, **Esc** pause/menu
- Minigames: arrows/WASD, spacebar, number/letter keys for MCQ answers
- Mouse click for menu buttons

## Colours & Branding

**Positioning disclaimer:** Massey University's name and colours are used descriptively
in this affectionate, fan-made **parody** created for a student hackathon. This is an
unofficial project with **no claim of endorsement** by Massey University or MUITSA, and
the **actual Massey logo/crest is NOT used anywhere** in the game. All art is original
placeholder work. Per the official brand library's own guidance, gold should not sit on
bright blue, so we keep gold for call-to-actions/highlights only.

**Primary palette — "official uni" zones (Lecture Hall, Library, Cafeteria, Flat, Exam):**
sourced from Massey University's published Brand Guidelines (brandlibrary.massey.ac.nz) —
search-confirmed on release day (all five hexes below match the guidelines).

| Role | Name | Hex | Source |
|------|------|-----|--------|
| Deep background / walls | Massey Dark Blue | `#0A2240` | official brand page |
| Zone plates / floors | Massey Blue | `#004b8d` | official brand page |
| Interactive highlights | Massey Light Blue | `#4789C8` | official brand page |
| Accents / player pop | Massey Bright Blue | `#25AAE1` | official brand page |
| Buttons / calls-to-action | Massey Gold | `#e4a024` | official brand page (Pantone 130C) |

**Usage:** Gold for menu buttons + "press E" prompts + win screen. Bright Blue for the
player character (contrasts against the darker blues). Light Blue for interactable
zone cues. Dark Blue for UI bar backgrounds / building shells. All HUD bars in Gold +
Dark Blue for readability on the map.

**"Student club" palette — MUITSA Clubroom zone:** a **purple + gold** scheme, after
MUITSA's own club colours. **No official MUITSA hex codes are published** (searched —
nothing reliable turned up, only an unrelated Ghanaian university using the same
acronym), so this is an **original colour choice inspired by "purple and gold"
branding**, NOT a verified MUITSA asset. (Fun fact: Massey's own guidelines include a
purple feature colour "Poroporo" `#812990` — we deliberately chose different purples
so the clubroom reads student-run, not official.)

| Role | Hex | Source |
|------|-----|--------|
| Clubroom floor / background | `#4A148C` (deep purple) | original pick |
| Club walls | `#7C3AED` (bright violet) | original pick |
| Club gold accent / signage | `#F5B300` (warm gold, brighter than Massey Gold) | original pick |
| Club text / light accents | `#FFEFD6` (cream) | original pick |

The bright-violet + gold combo contrasts hard against every Massey blue so the
clubroom reads as a separate, energetic, student-run space at a glance.

## Art / audio (placeholders — explicitly to be swapped before submission)
- Player = a bright-blue rounded square/`CharacterBody2D`; zones = flat colour `Area2D`
  plates with text signs; geese enemies = white square w/ orange square beak.
- One dark-blue sky background; HUD = `ProgressBar`s and `Label`s in the palette above.
- Audio: optional generated beeps via `AudioStreamGenerator` (no downloads).
- **Placeholder list for later polish:** proper sprites, walking animations, a title
  screen image, background music, sound effects, confetti particles.

## Architecture (Godot concepts used, kept simple)
- **Autoload `GameState`:** holds meters, day/number, event schedule, and cross-scene
  state so minigames can hand results back to the campus.
- **Signals** let zones tell the campus "player entered/left" and minigames shout
  "finished(result)" back up.
- Every scene has one `.tscn` + one `.gd` script. Minigames `change_scene` to campus
  with results already written into `GameState`.
- One map scene with zones as `Area2D` + a `Camera2D` that follows the player.

## Scope-cut list (cut in this order if time runs out)
1. Best-grade memory / extra win-screen jokes
2. Rush-to-Class minigame → replace with a 3-second "hold to not be late" timer
3. Generated audio beeps
4. Essay reaction minigame → replace with a plain "spend Friday library slot" choice
5. Pop quiz question bank variety (ships with 6–9 questions)
6. Particles/animations/kill-screens
7. Pause menu (Esc)
   ...NEVER cut: main menu, campus loop, meters, exam, win, lose, retry.

## What "done" looks like for the hackathon
Complete source project + a Linux export + a Windows/Linux export + a tested HTML5 zip
for itch.io. README with controls + itch link placeholder + AI-usage note.