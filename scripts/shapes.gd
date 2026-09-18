class_name Shapes
## Small static helpers for placeholder art. No runtime state.

## Build a filled circle polygon (16 sides is plenty chunky for a placeholder).
static func circle(cx: float, cy: float, r: float, sides: int = 16) -> PackedVector2Array:
    var pts := PackedVector2Array()
    for i in sides:
        var a: float = TAU * float(i) / float(sides)
        pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
    return pts