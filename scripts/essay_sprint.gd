extends Control
## Timed-tap minigame: hit SPACE/E when the needle is inside the green zone.
## Used for: finishing due assignments ("before the Wi-Fi drops"), the
## Software Engineering stand-up sprint, and the Food Science pavlova panel.
## Juice: gold burst on hits, red shake-flash on misses, per-attempt dots,
## and the gauge reads as a proper rounded instrument.

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

var needle: Control
var needle_inner: Panel
var feedback_lbl: Label
var attempts_lbl: Label
var gauge_layer: CanvasLayer
var dots_row: HBoxContainer

func _ready() -> void:
	theme = UiKit.theme()
	UiKit.backdrop(self)
	UiKit.fade_in(self)
	AudioFx.music("focus")
	var mode: Dictionary = GameState.event_mode
	mode_name = mode.get("mode", "assignment")
	_build_ui(mode)

func _build_ui(mode: Dictionary) -> void:
	var title := UiKit.label(mode.get("title", "DEADLINE"), 30, Palette.GOLD, true, 800)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position = Vector2(0, 44)
	add_child(title)

	var blurb := UiKit.label(mode.get("blurb", ""), 15, Palette.LIGHT, false, 500)
	blurb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	blurb.position = Vector2(0, 96)
	add_child(blurb)

	var prompt := UiKit.label(mode.get("prompt", "Hit SPACE in the green"), 19, Palette.PAPER, false, 600)
	prompt.set_anchors_preset(Control.PRESET_TOP_WIDE)
	prompt.position = Vector2(0, 146)
	add_child(prompt)

	# Gauge track (rounded, recessed).
	var track := Panel.new()
	track.anchor_left = 0.5
	track.anchor_right = 0.5
	track.offset_left = -GAUGE_W / 2.0 - 10
	track.offset_right = GAUGE_W / 2.0 + 10
	track.offset_top = 248
	track.offset_bottom = 316
	track.add_theme_stylebox_override("panel", UiKit.box(Palette.SUNK, 12, Palette.LIGHT, 1))
	add_child(track)

	# Green "good" zone (soft translucent).
	var zone := ColorRect.new()
	zone.color = Color(0.30, 0.72, 0.42, 0.55)
	zone.anchor_left = 0.5
	zone.anchor_right = 0.5
	zone.offset_left = -GREEN_HALF
	zone.offset_right = GREEN_HALF
	zone.offset_top = 252
	zone.offset_bottom = 312
	add_child(zone)

	# Needle (rounded bar that swings on a CanvasLayer in gauge space).
	gauge_layer = CanvasLayer.new()
	gauge_layer.layer = 1
	add_child(gauge_layer)
	needle = Control.new()
	needle.anchor_left = 0.5
	needle.anchor_right = 0.5
	needle.offset_left = -8
	needle.offset_right = 8
	needle.offset_top = 244
	needle.offset_bottom = 320
	gauge_layer.add_child(needle)
	needle_inner = Panel.new()
	needle_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	needle_inner.add_theme_stylebox_override("panel", UiKit.box(Palette.GOLD, 8))
	needle.add_child(needle_inner)

	# Attempt dots.
	dots_row = HBoxContainer.new()
	dots_row.anchor_left = 0.5
	dots_row.anchor_right = 0.5
	dots_row.offset_left = -70
	dots_row.offset_right = 70
	dots_row.offset_top = 334
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.add_theme_constant_override("separation", 14)
	add_child(dots_row)
	for i in ATTEMPTS:
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.draw.connect(_draw_dot.bind(i, dot))
		dots_row.add_child(dot)

	attempts_lbl = UiKit.label("", 15, Palette.PAPER, false, 500)
	attempts_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	attempts_lbl.position = Vector2(0, 365)
	add_child(attempts_lbl)

	feedback_lbl = UiKit.label("", 26, Palette.PAPER, false, 700)
	feedback_lbl.set_anchors_preset(Control.PRESET_CENTER)
	feedback_lbl.anchor_left = 0.5
	feedback_lbl.anchor_right = 0.5
	feedback_lbl.offset_left = -400
	feedback_lbl.offset_right = 400
	feedback_lbl.offset_top = 430
	feedback_lbl.offset_bottom = 480
	add_child(feedback_lbl)

	_update_attempts_lbl()

## One attempt dot: off = sunk, done = gold, green zones counted.
func _draw_dot(i: int, dot: Control) -> void:
	var done := i < attempts_done
	var good := i < greens
	var col := Palette.SAGE if good else (Palette.GOLD if done else Palette.SUNK)
	dot.draw_circle(dot.size * 0.5, 5.5, col)
	if done:
		dot.draw_circle(dot.size * 0.5, 2.0, Palette.DARK if good else Color(col.r, col.g, col.b, 0.9))

func _process(delta: float) -> void:
	if state == State.WAIT:
		t += delta * SPEED
		var half := GAUGE_W / 2.0 - GREEN_HALF
		needle_x = sin(t) * half
		needle.offset_left = needle_x - 8.0
		needle.offset_right = needle_x + 8.0
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
				needle_inner.color = Palette.GOLD
				_update_attempts_lbl()

func _judge_tap() -> void:
	if state != State.WAIT:
		return
	attempts_done += 1
	var at := needle.global_position + Vector2(0, -8)
	if absf(needle_x) < GREEN_HALF:
		greens += 1
		feedback_lbl.text = _green_line()
		feedback_lbl.add_theme_color_override("font_color", Palette.SAGE)
		UiKit.burst(self, at, Palette.GOLD, 16)
		AudioFx.sfx("correct")
	else:
		feedback_lbl.text = _miss_line()
		feedback_lbl.add_theme_color_override("font_color", Palette.RED)
		UiKit.flash(self, Palette.RED, 0.2)
		UiKit.burst(self, at, Palette.RED, 8)
		AudioFx.sfx("wrong")
	state = State.FEEDBACK
	feedback_timer = 0.8
	_update_attempts_lbl()
	for dot in dots_row.get_children():
		dot.queue_redraw()

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
	feedback_lbl.text = "%d / %d perfect" % [greens, ATTEMPTS]
	feedback_lbl.add_theme_color_override("font_color", Palette.GOLD)
	UiKit.pop_in(feedback_lbl)
	AudioFx.sfx("confirm")
	var next: String = GameState.finish_event({"greens": greens})
	await get_tree().create_timer(1.2).timeout
	UiKit.fade_and_switch(self, next)
