# Massey Uni Simulator — Game Design Doc

> Working title: **"Palmy Peril: Survive the Semester"**
> (affectionate parody — plain "Massey Uni Simulator" is the fallback)

## Pitch

You are a first-year student at a thinly-disguised, affectionately-parodied version of
Massey University Manawatū ("Massey North University" in-game, campus in a fictional
town we'll call Palmyton). Your only goal: survive 7 hilarious in-game days until
Graduation Day without running out of Energy, maxing out Stress, or letting your GPA
tank. Walk your little circle-person around a campus hub, spend each day's 3 action
slots wisely between lectures, library study, cafeteria refuels, and flat naps, and
survive the surprise events uni throws at you: pop quizzes, essay deadlines, a
frenzied rush to class dodging campus geese, and the final boss — Finals Week. Short,
laugh-out-loud, winnable in one focused 3–5 minute run, replayable for a better grade
and better jokes.

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
- GPA: −3 overnight (course content compunds/you forget stuff — keeps GPA pressurised)

### Zone activities (each costs 1 slot)
| Zone | Activity (press E) | Energy | Stress | GPA | Notes |
|------|--------------------|--------|--------|-----|-------|
| Lecture Hall | Attend lecture | −8 | +7 | +5 | Morning/Afternoon only. Can trigger Pop Quiz |
| Library ("The Spiral") | Study | −9 | +8 | +8 | Any slot |
| Library | Work on assignment | −4 | +5 | +8 | Only on the day it's due (else it's late!) |
| Cafeteria ("Food Hall") | Eat + memes | +20 | −10 | 0 | Any slot |
| Flat (Dorm) | Nap | +28 | −4 | 0 | Any slot (no, you can't nap your degree) |
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

## Controls
- **WASD / arrows** move, **E / Space** interact, **Esc** pause/menu
- Minigames: arrows/WASD, spacebar, number/letter keys for MCQ answers
- Mouse click for menu buttons

## Art / audio (placeholders — explicitly to be swapped before submission)
- Player = colored `ColorRect`/`CharacterBody2D` with a simple shape; zones = colored
  `Area2D` plates with text signs; enemies=(geese) = white square w/ orange square beak.
- One sky-blue background; HUD = `ProgressBar`s and `Label`s.
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
- One map scene with 5 zones as `Area2D` + a `Camera2D` that follows the player.

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