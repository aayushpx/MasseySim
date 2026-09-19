# ASSETS.md — asset sources & licenses

All art in this game is **custom-built flat/vector art generated natively in Godot**
(Polygon2D/Line2D/Node2D rigs, plus a small ground-gradient shader). Only fonts and
audio are imported from third parties. Everything below is free for commercial use;
attribution requirements are honoured where they exist.

## Why custom-built art instead of a sourced pack

We evaluated CC0 pack bases before building (per the project brief, "asset sourcing first"):

| Candidate | URL | License | Verdict |
|---|---|---|---|
| Kenney Top-down Shooter | https://kenney.nl/assets/top-down-shooter | CC0 | Tiles are generic fallout/shooter-style; characters are weapon poses (stand/gun/reload/hold) with **no clean walk cycle** — not a university student. Skipped. |
| Kenney City Kit (Suburban) | https://kenney.nl/assets/city-kit-suburban | CC0 | Pre-rendered 3D buildings (FBX/GLB/OBJ + 64px PNGs) with multi-tone soft shading that does not retint cleanly to a strict 5-colour brand palette; no characters. Skipped. |
| Kenney RPG Urban Kit | https://kenney-assets.itch.io/rpg-urban-kit | CC0 | Classic 16-bit pixel look with 4-dir walk characters; but pairing a pixel character with any non-pixel world would break the "one cohesive style" rule. Skipped for cohesion. |
| OGA Walking Character Set | https://opengameart.org/content/walking-character-set | CC0 | 8-bit top-down walk cycles; same cohesion argument. Skipped. |

Decision: custom flat-vector art keeps the licence story 100% self-contained (zero
external image licences), guarantees exact Massey-palette adherence, and removes any
style-mixing seams. Composition is kept disciplined (bold shapes, flat colour fields,
generous whitespace — "modern academic poster" energy) per the art direction.

## Fonts — Google Fonts (SIL Open Font License)

- **Fraunces** (display / headers) — https://fonts.google.com/specimen/Fraunces
  - Source file: `https://github.com/google/fonts/raw/main/ofl/fraunces/Fraunces[SOPT,WONK,opsz,wght].ttf`
  - License: SIL Open Font License 1.1. Free for commercial use; font files may be
    redistributed with the game (they are — see assets/fonts/Fraunces.ttf).
  - Copyright noted in the font metadata; retained in the font binary.
- **Work Sans** (body / UI) — https://fonts.google.com/specimen/Work+Sans
  - Source file: `https://github.com/google/fonts/raw/main/ofl/worksans/WorkSans[wght].ttf`
  - License: SIL Open Font License 1.1. Same terms as above.

## Audio

All audio ships inside the game at `assets/audio/`. License texts from the
original packs are committed alongside the files.

### Music — Kevin MacLeod (incompetech.com), CC BY 4.0

Requires attribution (given in-game on the main menu and in README credits):
> Music: Kevin MacLeod (incompetech.com), Licensed under Creative Commons:
> By Attribution 4.0 License, http://creativecommons.org/licenses/by/4.0/

| File | Track | Source |
|---|---|---|
| `music_menu.mp3` | Carefree | https://incompetech.com/music/royalty-free/mp3-royaltyfree/Carefree.mp3 |
| `music_campus.mp3` | The Builder | https://incompetech.com/music/royalty-free/mp3-royaltyfree/The%20Builder.mp3 |
| `music_focus.mp3` | Clean Soul | https://incompetech.com/music/royalty-free/mp3-royaltyfree/Clean%20Soul.mp3 |

Swap note: any of Kevin MacLeod's other CC-BY loops can be dropped in by
replacing these files (names kept; no code changes needed).

### SFX — Kenney.nl, CC0 (no attribution required)

| File | Source pack | Used for |
|---|---|---|
| `sfx_click.ogg` | Interface Sounds | button press |
| `sfx_hover.ogg` | UI Audio | button hover |
| `sfx_select.ogg` | Interface Sounds | zone popup opens |
| `sfx_confirm.ogg` | Interface Sounds | minigame finish / win |
| `sfx_back.ogg` | Interface Sounds | back-to-menu |
| `sfx_correct.ogg` | Interface Sounds | quiz/essay green taps |
| `sfx_wrong.ogg` | Interface Sounds | quiz/essay misses, goose hits, lose |
| `sfx_tick.ogg` | Interface Sounds | day-transition wipe |
| `sfx_switch.ogg` | Interface Sounds | (reserved for future toggles) |

Packs: https://kenney.nl/assets/interface-sounds and https://kenney.nl/assets/ui-audio
(CC0; "credit to Kenney or www.kenney.nl would be nice but is not mandatory").

## Brand & theming

All in-game signage, banners and props are original/parody dressing — no Massey
logo or crest is used. The colour palette (documented in DESIGN.md) is drawn from
Massey's public brand palette and the MUITSA purple/gold club identity.