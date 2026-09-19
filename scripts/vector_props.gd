class_name Props
## Small build-your-own-vector-art helpers. Everything returns geometry or
## ready-made Polygon2D nodes so the flat-vector look stays consistent.

## Rounded rectangle as a polygon centred on (0,0).
static func rounded_rect(w: float, h: float, r: float, step: int = 6) -> PackedVector2Array:
    var pts := PackedVector2Array()
    var hw := w * 0.5
    var hh := h * 0.5
    r = minf(r, minf(hw, hh))
    var centres := [Vector2(hw - r, -hh + r), Vector2(hw - r, hh - r), Vector2(-hw + r, hh - r), Vector2(-hw + r, -hh + r)]
    for ci in 4:
        var c: Vector2 = centres[ci]
        var start_deg: float
        match ci:
            0: start_deg = PI * 1.5
            1: start_deg = 0.0
            2: start_deg = PI * 0.5
            _: start_deg = PI
        for i in step:
            var a: float = start_deg + TAU / 4.0 * float(i) / float(step)
            pts.append(c + Vector2(cos(a), sin(a)) * r)
    return pts

## A horizontal ellipse (top-down body/head blobs).
static func ellipse(rx: float, ry: float, step: int = 20) -> PackedVector2Array:
    var pts := PackedVector2Array()
    for i in step:
        var a: float = TAU * float(i) / float(step)
        pts.append(Vector2(cos(a) * rx, sin(a) * ry))
    return pts

## Stripe: a thin rectangle centred on (0,0) used for legs/arms/cables.
static func bar(w: float, h: float) -> PackedVector2Array:
    return rounded_rect(w, h, minf(w, h) * 0.5, 3)

## Convenience: make a Polygon2D.
static func poly(p: PackedVector2Array, col: Color, pos: Vector2 = Vector2.ZERO, z: int = 0) -> Polygon2D:
    var n := Polygon2D.new()
    n.polygon = p
    n.color = col
    n.position = pos
    n.z_index = z
    return n

## Outlined rounded panel polygon (draw a rounded rect as a stroke-like ring).
static func ring(w: float, h: float, r: float, thickness: float = 3.0, step: int = 8) -> PackedVector2Array:
    return rounded_rect(w + thickness, h + thickness, r + thickness, step)