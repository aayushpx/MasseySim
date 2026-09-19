class_name PromptChip
extends Control
## Bottom-prompt / toast chip. A Control that sizes itself to its text and
## draws its own backing chip + centered text in a single canvas item via
## draw_string (the same proven path the slot pills use - connecting Label.draw
## silently suppresses a Label's intrinsic text, verified in the readability fix).
## The chip's design values are the single source of truth for every small
## text-backing chip in the game (prompt, toast, menu button, popup buttons),
## so they all share radius / padding / border and read as one system.

const CHIP_RADIUS := 10.0
const CHIP_BORDER := Palette.BLUE
const PAD_X := 18.0
const PAD_Y := 8.0
const BASE_BG := Color(0.02, 0.06, 0.13, 1.0)

static func chip_style(alpha: float = 0.88, hover: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = BASE_BG * Color(1, 1, 1, alpha)
	s.set_corner_radius_all(CHIP_RADIUS)
	s.border_color = Palette.GOLD if hover else CHIP_BORDER
	s.set_border_width_all(1)
	s.content_margin_left = PAD_X
	s.content_margin_right = PAD_X
	s.content_margin_top = PAD_Y
	s.content_margin_bottom = PAD_Y
	return s

var _t := ""

## The point on screen the chip stays centred on as the text grows/shrinks.
var center := Vector2.ZERO

var text: String:
	get:
		return _t
	set(value):
		_t = value
		_relayout()
		queue_redraw()

var font_weight := 600
var font_size := 18
var text_color := Palette.GOLD
var outline_width := 3
var alpha := 0.88

func _ready() -> void:
	_relayout()

func _relayout() -> void:
	if _t == "":
		size = Vector2.ZERO
		return
	var f: Font = CampusDecor.body_font(font_weight)
	var tw: float = f.get_string_size(_t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var cw: float = tw + PAD_X * 2.0 + outline_width * 2.0
	var ch: float = font_size + PAD_Y * 2.0 + outline_width * 2.0
	size = Vector2(ceilf(cw), ceilf(ch))
	position = Vector2(center.x - size.x * 0.5, center.y - size.y * 0.5)

func _draw() -> void:
	if _t == "":
		return
	var box := Rect2(Vector2.ZERO, size)
	draw_style_box(chip_style(alpha), box)
	var f: Font = CampusDecor.body_font(font_weight)
	var asc: float = f.get_ascent(font_size)
	var desc: float = f.get_descent(font_size)
	var baseline: float = size.y * 0.5 + (asc - desc) * 0.5
	var origin := Vector2(0, baseline)
	draw_string_outline(f, origin, _t, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, outline_width, BASE_BG)
	draw_string(f, origin, _t, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, text_color)