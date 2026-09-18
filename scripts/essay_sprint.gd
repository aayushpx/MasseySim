extends Control
## Timed-tap minigame: hit SPACE/E when the needle is inside the green zone.
## Used for: finishing due assignments ("before the Wi-Fi drops"), the
## Software Engineering stand-up sprint, and the Food Science pavlova panel.

const ATTEMPTS := 5
const GAUGE_W := 840.0
const GREEN_HALF := 90.0
const SPEED := 4.2

enum State { WAIT, FEEDBACK, DONE }

var mode_name := "assignment"
var state := State.WAIT
var needle_x := 0.0
var t := 0.0
var attempts_done := 0
var greens := 0
var feedback_timer := 0.0

var needle: ColorRect
var feedback_lbl: Label
var attempts_lbl: Label

const BG := Color("#0A2240")
const GOLD := Color("#e4a024")
const LIGHT := Color("#4789C8")
const GREEN := Color("#7BC950")
const RED := Color("#d64848")
const WHITE := Color("#f0f5ff")

func _ready() -> void:
    var mode: Dictionary = GameState.event_mode
    mode_name = mode.get("mode", "assignment")
    _build_ui(mode)

func _build_ui(mode: Dictionary) -> void:
    var bg := ColorRect.new()
    bg.color = BG
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var title := Label.new()
    title.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title.position = Vector2(0, 50)
    title.add_theme_font_size_override("font_size", 32)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", GOLD)
    title.text = mode.get("title", "DEADLINE")
    add_child(title)

    var blurb := Label.new()
    blurb.set_anchors_preset(Control.PRESET_TOP_WIDE)
    blurb.position = Vector2(0, 100)
    blurb.add_theme_font_size_override("font_size", 16)
    blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    blurb.add_theme_color_override("font_color", LIGHT)
    blurb.text = mode.get("blurb", "")
    add_child(blurb)

    var prompt := Label.new()
    prompt.set_anchors_preset(Control.PRESET_TOP_WIDE)
    prompt.position = Vector2(0, 150)
    prompt.add_theme_font_size_override("font_size", 20)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_color_override("font_color", WHITE)
    prompt.text = mode.get("prompt", "Hit SPACE in the green")
    add_child(prompt)

    # Track background, centred.
    var track := ColorRect.new()
    track.color = Color("#123a6b")
    track.anchor_left = 0.5
    track.anchor_right = 0.5
    track.offset_left = -GAUGE_W / 2.0 - 8
    track.offset_right = GAUGE_W / 2.0 + 8
    track.offset_top = 250
    track.offset_bottom = 312
    add_child(track)

    # Green "good" zone.
    var zone := ColorRect.new()
    zone.color = Color(0.48, 0.79, 0.31, 0.5)
    zone.anchor_left = 0.5
    zone.anchor_right = 0.5
    zone.offset_left = -GREEN_HALF
    zone.offset_right = GREEN_HALF
    zone.offset_top = 250
    zone.offset_bottom = 312
    add_child(zone)

    # The moving needle.
    needle = ColorRect.new()
    needle.color = GOLD
    needle.anchor_left = 0.5
    needle.anchor_right = 0.5
    needle.offset_top = 244
    needle.offset_bottom = 318
    needle.offset_left = -6
    needle.offset_right = 6
    add_child(needle)

    attempts_lbl = Label.new()
    attempts_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
    attempts_lbl.position = Vector2(0, 330)
    attempts_lbl.add_theme_font_size_override("font_size", 18)
    attempts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    attempts_lbl.add_theme_color_override("font_color", WHITE)
    add_child(attempts_lbl)

    feedback_lbl = Label.new()
    feedback_lbl.set_anchors_preset(Control.PRESET_CENTER)
    feedback_lbl.anchor_left = 0.5
    feedback_lbl.anchor_right = 0.5
    feedback_lbl.offset_left = -400
    feedback_lbl.offset_right = 400
    feedback_lbl.offset_top = 390
    feedback_lbl.offset_bottom = 440
    feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback_lbl.add_theme_font_size_override("font_size", 26)
    add_child(feedback_lbl)

    _update_attempts_lbl()

func _process(delta: float) -> void:
    if state == State.WAIT:
        t += delta * SPEED
        # Oscillate across the gauge, centred, full width.
        var half := GAUGE_W / 2.0 - GREEN_HALF
        needle_x = sin(t) * half
        needle.offset_left = needle_x - 6.0
        needle.offset_right = needle_x + 6.0
        if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
            _judge_tap()
    elif state == State.FEEDBACK:
        feedback_timer -= delta
        if feedback_timer <= 0.0:
            if attempts_done >= ATTEMPTS:
                _finish()
            else:
                state = State.WAIT
                feedback_lbl.text = ""
                _update_attempts_lbl()

func _judge_tap() -> void:
    if state != State.WAIT:
        return
    attempts_done += 1
    if absf(needle_x) < GREEN_HALF:
        greens += 1
        feedback_lbl.add_theme_color_override("font_color", GREEN)
        feedback_lbl.text = _green_line()
    else:
        feedback_lbl.add_theme_color_override("font_color", RED)
        feedback_lbl.text = _miss_line()
    state = State.FEEDBACK
    feedback_timer = 0.8
    _update_attempts_lbl()

func _green_line() -> String:
    match mode_name:
        "standup": return "Stand-up! The scrum master nods. Slowly."
        "pavlova": return "PERFECT. The judge hums approvingly."
        _: return "Paragraph locked in. The Wi-Fi lives another day."
    return ""

func _miss_line() -> String:
    match mode_name:
        "standup": return "The scrum master is unmoved. Yikes."
        "pavlova": return "The judge writes something ominous."
        _: return "The Wi-Fi flickers. You did your best."
    return ""

func _update_attempts_lbl() -> void:
    attempts_lbl.text = "Attempt %d / %d" % [min(attempts_done + 1, ATTEMPTS), ATTEMPTS]

func _finish() -> void:
    state = State.DONE
    feedback_lbl.add_theme_color_override("font_color", GOLD)
    feedback_lbl.text = "%d / %d perfect" % [greens, ATTEMPTS]
    var next: String = GameState.finish_event({"greens": greens})
    await get_tree().create_timer(1.2).timeout
    get_tree().change_scene_to_file(next)