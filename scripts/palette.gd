class_name Palette
## Central colour constants. Everything in the game pulls from here so the
## Massey palette can never drift.

# --- Massey brand palette -----------------------------------------------
const DARK := Color("#0A2240")       # deep navy: ground, hair, heavy text
const BLUE := Color("#004b8d")       # mid Massey blue: hoodie, primary panels
const LIGHT := Color("#4789C8")      # light steel blue: secondary fills
const BRIGHT := Color("#25AAE1")     # bright accent: energy, highlights, correct
const GOLD := Color("#e4a024")       # gold: emphasis, rewards, UI accents
const RED := Color("#d64848")        # harsh red: damage, wrong answers, stress

# --- MUITSA club identity ------------------------------------------------
const PURPLE_DARK := Color("#4A148C")
const PURPLE := Color("#7C3AED")
const MU_GOLD := Color("#F5B300")
const MU_CREAM := Color("#FFEFD6")

# --- Neutrals (support, kept desaturated so they stay out of the brand) --
const INK := Color("#06152b")        # darker than DARK for shadows/borders
const FOG := Color("#c9d8ee")        # light lavender-grey text on dark
const PAPER := Color("#f6f2ea")      # warm off-white for light surfaces
const SUNK := Color("#0c1e38")       # recessed track fill (bars, slots)

# --- Flat-vector skin/hair (non-brand, kept few & quiet) ----------------
const SKIN := Color("#eec091")
const HAIR := Color("#0A2240")

# --- Flora (kept muted so it never competes with the brand) -------------
const SAGE := Color("#6fae82")
const LEAF := Color("#3f8f5f")

# --- Time-of-day tint (slot -> CanvasModulate colour) --------------------
const TINT_MORNING := Color("#ffffff")
const TINT_AFTERNOON := Color("#ffd99c")
const TINT_EVENING := Color("#a4bde6")

static func slot_tint(slot_name: String) -> Color:
    match slot_name:
        "Afternoon":
            return TINT_AFTERNOON
        "Evening":
            return TINT_EVENING
    return TINT_MORNING