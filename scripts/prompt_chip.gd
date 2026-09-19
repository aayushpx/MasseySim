class_name PromptChip
extends Control
## Bottom-prompt / toast chip. A Control that draws its own backing chip and
## centered text in a single canvas item via draw_string. Deliberately NOT a
## Label: connecting Label.draw silently suppresses the Label's intrinsic text
## (proved with the refA/refB controls in tests/shot_tool.gd), while draw_string
## on a plain Control renders reliably (same path the slot pills use).
## The dark chip + text outline keep the text legible over any world backing.

var _t := ""

var text: String:
	get:
		return _t
	set(value):
		_t = value
		queue_redraw()

var chip_width := 300.0
var font_weight := 600
var font_size := 18
var text_color := Palette.GOLD
var outline_width := 3

func _draw() -> void:
	if _t == "":
		return
	var box := Rect2(Vector2(size.x * 0.5 - chip_width * 0.5, 0), Vector2(chip_width, size.y))
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(0.02, 0.06, 0.13, 0.88)
	chip.set_corner_radius_all(10)
	chip.border_color = Palette.BLUE
	chip.set_border_width_all(1)
	draw_style_box(chip, box)
	var f := CampusDecor.body_font(font_weight)
	var origin := Vector2(size.x * 0.5, size.y * 0.5 + font_size * 0.4)
	draw_string_outline(f, origin, _t, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, outline_width, Color(0.02, 0.06, 0.13, 1.0))
	draw_string(f, origin, _t, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, text_color)