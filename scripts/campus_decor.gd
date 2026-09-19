class_name CampusDecor
## Statically-built flat-vector props for dressing the six campus zones.
## Everything shares the Massey palette and the same rounded-shape language so
## the world reads as one deliberately composed illustration rather than a
## pile of placeholder boxes.

static var _body_font: FontFile
static var _display_font: FontFile

static func body_font(weight: int = 500) -> Font:
	_ensure_fonts()
	var fv := FontVariation.new()
	fv.base_font = _body_font
	fv.variation_opentype = {"wght": float(weight)}
	return fv

static func display_font(weight: int = 700) -> Font:
	_ensure_fonts()
	var fv := FontVariation.new()
	fv.base_font = _display_font
	fv.variation_opentype = {"wght": float(weight)}
	return fv

static func _ensure_fonts() -> void:
	if _body_font != null:
		return
	_body_font = FontFile.new()
	_body_font.load_dynamic_font("res://assets/fonts/WorkSans.ttf")
	_display_font = FontFile.new()
	_display_font.load_dynamic_font("res://assets/fonts/Fraunces.ttf")

## Wrap a set of nodes in a positioned container "decor".
static func group(nodes: Array) -> Node2D:
	var n := Node2D.new()
	for c in nodes:
		n.add_child(c)
	return n

static func _rrect(w: float, h: float, r: float, col: Color, pos: Vector2 = Vector2.ZERO, z: int = 0) -> Polygon2D:
	return Props.poly(Props.rounded_rect(w, h, r, 4), col, pos, z)

static func _text(text: String, pos: Vector2, size: int, col: Color, display: bool = false, weight: int = 600) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_override("font", display_font(weight) if display else body_font(weight))
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_constant_override("outline_size", 0)
	return lbl

# --- Zones -----------------------------------------------------------------

## Lecture hall dressing. plate = floor rect (w,h centred on origin).
static func lecture_hall(w: float, h: float) -> Node2D:
	var out: Array = []

	out.append(_rrect(w - 40, 34, 6, Palette.INK, Vector2(0, -h * 0.5 + 60)))
	out.append(_rrect(150, 84, 4, Palette.PAPER, Vector2(0, -h * 0.5 + 34), 2))
	out.append(_rrect(150 + 8, 4, 1.5, Palette.INK, Vector2(0, -h * 0.5 + 77), 3))
	out.append(_rrect(110, 22, 3, Palette.LIGHT, Vector2(0, -h * 0.5 + 33), 3))
	out.append(_rrect(34, 24, 4, Palette.GOLD, Vector2(-54, -h * 0.5 + 78), 3))
	out.append(_rrect(28, 30, 3, Palette.INK, Vector2(-54, -h * 0.5 + 96), 2))
	out.append(_text("FINALS IN SESSION? NO PRESSURE.", Vector2(-146, -h * 0.5 + 2), 12, Palette.FOG, false, 600))
	for i in 3:
		out.append(_rrect(54, 9, 3, Palette.GOLD, Vector2(-84 + i * 84, -h * 0.5 + 49), 4))

	for r in 3:
		var y: float = -h * 0.5 + 128 + r * 44
		for s in 5:
			var x: float = -w * 0.5 + 36 + 40 + s * 68
			out.append(_rrect(58, 20, 3, Palette.LIGHT, Vector2(x, y), 2))
			out.append(_rrect(58, 3, 1.5, Palette.INK, Vector2(x, y - 10), 3))
			out.append(_rrect(20, 20, 6, Palette.BRIGHT, Vector2(x, y + 12), 2))

	out.append(bookshelf(Vector2(-w * 0.5 + 34, 0), 58, 150, 3))
	out.append(bookshelf(Vector2(w * 0.5 - 34, 0), 58, 150, 3))
	out.append(plant(Vector2(-w * 0.5 + 22, -h * 0.5 + 110)))
	out.append(plant(Vector2(w * 0.5 - 22, -h * 0.5 + 110)))
	out.append(classroom_life(w, h))
	return group(out)

## Ambient life for the lecture hall: clock, dust motes, a plant, a silhouette.
static func classroom_life(w: float, h: float) -> Node2D:
	var life := Node2D.new()
	life.name = "Life"

	var clock := Node2D.new()
	clock.name = "Clock"
	clock.position = Vector2(w * 0.5 - 50, -h * 0.5 + 44)
	life.add_child(clock)
	clock.add_child(Props.poly(Props.ellipse(16, 16, 18), Palette.INK, Vector2.ZERO, 2))
	clock.add_child(Props.poly(Props.ellipse(14, 14, 18), Palette.PAPER, Vector2.ZERO, 3))
	for t in 12:
		var a := TAU * t / 12.0
		clock.add_child(Props.poly(Props.ellipse(1.6, 1.6, 4), Palette.INK, Vector2(cos(a), sin(a)) * 11.0, 4))
	var hour := Props.poly(Props.bar(2.4, 8.0), Palette.INK, Vector2(0, -3), 5)
	hour.name = "Hour"
	clock.add_child(hour)
	var second := Props.poly(Props.bar(1.2, 12.0), Palette.GOLD, Vector2(0, -4), 6)
	second.name = "Second"
	clock.add_child(second)

	var dust := Node2D.new()
	dust.name = "Dust"
	life.add_child(dust)
	for i in 3:
		var mote := Node2D.new()
		mote.name = "Mote%d" % i
		mote.position = Vector2(-50 + i * 30, -h * 0.5 + 22 + i)
		var dot := Props.poly(Props.ellipse(2.2, 2.2, 5), Palette.PAPER, Vector2.ZERO, 8)
		dot.modulate.a = 0.5
		mote.add_child(dot)
		dust.add_child(mote)

	var pot := plant(Vector2(-w * 0.5 + 22, -h * 0.5 + 110))
	pot.name = "Plant"
	life.add_child(pot)

	var npc := Node2D.new()
	npc.name = "Student"
	npc.position = Vector2(-64, -h * 0.5 + 118)
	npc.add_child(Props.poly(Props.ellipse(12, 10, 16), Palette.INK, Vector2(0, -12), 5))
	life.add_child(npc)
	return life

## Generic bookshelf unit. `pos` is the group origin.
static func bookshelf(pos: Vector2, unit_w: float, height: float, shelves: int) -> Node2D:
	var out: Array = []
	out.append(_rrect(unit_w + 8, height + 8, 4, Palette.INK, Vector2.ZERO))
	var sh: float = (height - 8) / float(shelves)
	for i in shelves:
		out.append(_rrect(unit_w, sh - 6, 2, Palette.LIGHT, Vector2(0, -height * 0.5 + 4 + sh * i + sh * 0.5)))
		var n_books: int = 4 + (i + shelflake()) % 3
		for b in n_books:
			var tones := [Palette.GOLD, Palette.BLUE, Palette.BRIGHT, Palette.PURPLE, Palette.SAGE]
			out.append(_rrect(unit_w * 0.16, sh - 14, 1.5, tones[(i + b) % tones.size()],
				Vector2(-unit_w * 0.5 + 6 + b * (unit_w - 12) / n_books, -height * 0.5 + 4 + sh * i + sh - 7)))
	var n := group(out)
	n.position = pos
	return n

static var _seed := 0
static func shelflake() -> int:
	_seed = (_seed + 1) % 7
	return _seed

## Potted plant: pot + two foliage discs.
static func plant(pos: Vector2) -> Node2D:
	var out: Array = []
	out.append(_rrect(20, 18, 4, Palette.SUNK, Vector2.ZERO))
	out.append(_rrect(24, 7, 2, Palette.BLUE, Vector2.ZERO, 1))
	out.append(Props.poly(Props.ellipse(17, 17, 16), Palette.SAGE, Vector2(0, -12), 2))
	out.append(Props.poly(Props.ellipse(10, 10, 14), Palette.LEAF, Vector2(6, -16), 3))
	var n := group(out)
	n.position = pos
	return n

## Cafeteria counter block.
static func cafe_counter(pos: Vector2, cw: float) -> Node2D:
	var out: Array = []
	out.append(_rrect(cw, 26, 6, Palette.PURPLE_DARK if _seeded_bool() else Palette.BLUE, pos))
	out.append(_rrect(cw - 12, 10, 3, Palette.PAPER, pos + Vector2(0, -9), 2))
	var n: int = int(cw / 46.0)
	for s in n:
		var sx: float = -cw * 0.5 + 23 * (s * 2 + 1)
		out.append(_rrect(14, 14, 7, Palette.GOLD, pos + Vector2(sx, 22), 2))
	return group(out)

static func _seeded_bool() -> bool:
	shelflake()
	return _seed % 2 == 0

## Dorm bed: mattress + pillow + blanket.
static func bed(pos: Vector2, bw: float) -> Node2D:
	var out: Array = []
	out.append(_rrect(bw, 46, 6, Palette.LIGHT, pos))
	out.append(_rrect(bw - 10, 26, 6, Palette.BRIGHT, pos + Vector2(0, 2), 2))
	out.append(_rrect(14, 10, 3, Palette.PAPER, pos + Vector2(-bw * 0.5 + 8, -8), 3))
	return group(out)

## Library reading table.
static func reading_table(pos: Vector2, w: float) -> Node2D:
	var out: Array = []
	out.append(_rrect(w, 22, 4, Palette.SUNK, pos))
	out.append(_rrect(w - 8, 4, 2, Palette.PAPER, pos + Vector2(0, -9), 2))
	for s in [0, 1]:
		out.append(_rrect(16, 16, 5, Palette.BRIGHT, pos + Vector2(-w * 0.5 + 14 + s * (w - 28), 16), 2))
	out.append(_rrect(10, 16, 5, Palette.GOLD, pos + Vector2(0, -8), 3))
	return group(out)

## MUITSA clubroom banner: purple banner, gold fringe + lettering.
static func banner(pos: Vector2, bw: float, bh: float) -> Node2D:
	var out: Array = []
	out.append(_rrect(bw, bh, 4, Palette.PURPLE_DARK, pos, 2))
	out.append(_rrect(bw - 18, bh - 16, 3, Palette.PURPLE, pos, 2))
	for i in 9:
		out.append(_rrect(3, 14, 1.5, Palette.MU_GOLD, pos + Vector2(-bw * 0.5 + 14 + i * 18, bh * 0.5 + 5), 1))
	out.append(_text("MUITSA", pos + Vector2(-bw * 0.5 + 16, -bh * 0.5 + 8), 30, Palette.MU_CREAM, true, 800))
	out.append(_text("GAME NIGHT EVERY FRIDAY", pos + Vector2(-bw * 0.5 + 16, -bh * 0.5 + 46), 12, Palette.MU_GOLD, false, 700))
	return group(out)

## Exam hall: strict rows of single desks.
static func exam_rows(pos: Vector2, w: float, rows: int) -> Node2D:
	var out: Array = []
	for r in rows:
		var y: float = pos.y + r * 30
		for s in 5:
			var x: float = pos.x - w * 0.5 + 34 + s * 62
			out.append(_rrect(52, 16, 2, Palette.SUNK, Vector2(x, y)))
			out.append(_rrect(13, 13, 4, Palette.BRIGHT, Vector2(x, y + 12), 2))
	return group(out)
