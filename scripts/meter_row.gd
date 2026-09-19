class_name MeterRow
extends Control
## A fully-drawn meter row: vector icon chip + label + rounded track + gold
## fill + numeric readout. Painted entirely in _draw so it never fights the
## default theme.

const W := 300.0
const H := 44.0
const ICON_R := 14.0

var key := "energy"
var value := 0.0
var _label := "ENERGY"
var _icon_tone := Palette.BRIGHT
var _max := 100.0

func setup(k: String) -> void:
    key = k
    custom_minimum_size = Vector2(W, H)
    match k:
        "energy":
            _label = "ENERGY"; _icon_tone = Palette.BRIGHT
        "stress":
            _label = "STRESS"; _icon_tone = Palette.GOLD
        "gpa":
            _label = "GPA"; _icon_tone = Palette.LIGHT
    value = GameState[k]
    _max = GameState.GPA_MAX

func set_value(v: float) -> void:
    value = v
    queue_redraw()

func icon_pos() -> Vector2:
    return Vector2(ICON_R + 2, H * 0.5)

func _draw() -> void:
    var r := Rect2(Vector2.ZERO, size)
    var y_mid := H * 0.5

    # Icon chip.
    draw_circle(Vector2(ICON_R + 2, y_mid), ICON_R + 3, Palette.SUNK)
    draw_circle(Vector2(ICON_R + 2, y_mid), ICON_R, Color(_icon_tone.r, _icon_tone.g, _icon_tone.b, 0.25))
    _draw_icon(Vector2(ICON_R + 2, y_mid))

    # Label.
    var label_font := CampusDecor.body_font(600)
    draw_string(label_font, Vector2(30, 12), _label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.FOG)

    # Track + fill.
    var track := Rect2(30, y_mid - 4, size.x - 30 - 44, 10)
    draw_rect(track, Palette.SUNK, true)
    var fw: float = clampf(value / _max, 0.0, 1.0) * track.size.x
    if fw > 0.5:
        draw_rect(Rect2(track.position, Vector2(fw, track.size.y)), _icon_tone, true)

    # Numeric readout, right-aligned in the row.
    var nf := CampusDecor.body_font(700)
    draw_string(nf, Vector2(size.x - 40, 12), "%3.0f" % value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.PAPER)

func _draw_icon(centre: Vector2) -> void:
    match key:
        "energy":
            # Lightning bolt.
            var bolt := PackedVector2Array([
                centre + Vector2(2, -8), centre + Vector2(-5, 2), centre + Vector2(-1, 2),
                centre + Vector2(-2, 8), centre + Vector2(5, -2), centre + Vector2(1, -2),
            ])
            draw_colored_polygon(bolt, Palette.BRIGHT)
        "stress":
            # Zigzag squiggle.
            var pts: PackedVector2Array = PackedVector2Array()
            for i in 7:
                pts.append(centre + Vector2(-6 + i * 2, -6 if i % 2 == 0 else 6))
            draw_polyline(pts, Palette.GOLD, 2.0)
            pts.append(centre + Vector2(7, 8))
            draw_polyline(PackedVector2Array([centre + Vector2(7, 8), centre + Vector2(8, 6)]), Palette.GOLD, 2.0)
        "gpa":
            # Graduation cap.
            var cap := PackedVector2Array([
                centre + Vector2(0, -8), centre + Vector2(10, -4), centre + Vector2(0, 0), centre + Vector2(-10, -4),
            ])
            draw_colored_polygon(cap, Palette.LIGHT)
            draw_line(centre + Vector2(0, 0), centre + Vector2(0, 4), Palette.LIGHT, 2.0)
            draw_line(centre + Vector2(-3, 5), centre + Vector2(3, 5), Palette.LIGHT, 2.0)