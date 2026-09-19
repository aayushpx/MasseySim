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

## Soft elliptical drop shadow under a prop: dark, translucent, set just
## below the object's z so it paints on the floor plate.
static func soft_shadow(sx: float, sy: float, pos: Vector2, alpha: float = 0.26) -> Polygon2D:
	return Props.poly(Props.ellipse(sx, sy, 16), Color(0.0, 0.0, 0.0, alpha), pos, 0)

## Lecture hall dressing.
## Composition logic:
##  - FOCAL: the board + podium sit front-center; every prop faces that wall.
##  - BODY: two desk BANKS (2 rows x 2 cols) flank a clear center AISLE that
##    runs straight up to the board; outer margins stay open as walkways so the
##    space reads as "approaching the front", never edge-to-edge clutter.
##  - CLUSTERS: back corners group related pieces - a READING NOOK (shelf +
##    armchair + lamp + side table) and a LOUNGE (two facing chairs + table),
##    instead of chairs and lamps scattered around the walls.
##  -BREATHING: front band, center aisle, side lanes and the back walkway are
##    intentionally empty for the player to move through.
static func lecture_hall(w: float, h: float) -> Node2D:
	var out: Array = []
	var depth: Array = []

	# --- FOCAL: board wall (front-center). ---
	var plinth := _rrect(w - 40, 34, 6, Palette.INK, Vector2(0, -h * 0.5 + 60))
	var board := _rrect(120, 84, 4, Palette.PAPER, Vector2(0, -h * 0.5 + 34), 2)
	out.append(plinth)
	out.append(board)
	out.append(_rrect(128, 4, 1.5, Palette.INK, Vector2(0, -h * 0.5 + 77), 3))
	out.append(_rrect(88, 22, 3, Palette.LIGHT, Vector2(0, -h * 0.5 + 33), 3))
	out.append(_rrect(40, 24, 4, Palette.GOLD, Vector2(-44, -h * 0.5 + 80), 3))
	out.append(_rrect(30, 26, 3, Palette.INK, Vector2(-44, -h * 0.5 + 96), 2))
	out.append(_text("FINALS IN SESSION? NO PRESSURE.", Vector2(-120, -h * 0.5 - 6), 12, Palette.FOG, false, 600))
	for i in 3:
		out.append(_rrect(40, 8, 3, Palette.GOLD, Vector2(-40 + i * 40, -h * 0.5 + 49), 4))

	# --- BODY: two desk banks facing the board, centre aisle clear. ---
	# Left bank x: -126 / -50, right bank x: 50 / 126; rows at front y=-h/2+134 and -h/2+178.
	var bank_x := [-126.0, -50.0, 50.0, 126.0]
	for row_xs in 2:
		var y: float = -h * 0.5 + 134 + row_xs * 44
		for s in 4:
			var x: float = bank_x[s]
			out.append(soft_shadow(34, 7, Vector2(x, y), 0.18))
			out.append(_rrect(58, 20, 3, Palette.LIGHT, Vector2(x, y), 2))
			out.append(_rrect(58, 3, 1.5, Palette.INK, Vector2(x, y - 10), 3))
			out.append(_rrect(20, 20, 6, Palette.BRIGHT, Vector2(x, y + 12), 2))

	# Front-corner plants frame the focal board.
	var plant_tl := plant(Vector2(-w * 0.5 + 22, -h * 0.5 + 110))
	var plant_tr := plant(Vector2(w * 0.5 - 22, -h * 0.5 + 110))
	out.append(soft_shadow(13, 7, Vector2(-w * 0.5 + 24, -h * 0.5 + 116)))
	out.append(soft_shadow(13, 7, Vector2(w * 0.5 - 24, -h * 0.5 + 116)))
	out.append(plant_tl)
	out.append(plant_tr)

	# --- CLUSTER 1: reading nook (back-left). Shelf on the back wall, chair in
	#     front of it, pool lamp + side table close at hand. One obvious zone.
	var nook_shelf := bookshelf(Vector2(-126, 92), 58, 120, 4)
	out.append(nook_shelf)
	out.append(rug(Vector2(-94, 116)))
	out.append(armchair(Vector2(-90, 112), 0.9))
	out.append(side_table(Vector2(-52, 122)))
	out.append(floor_lamp(Vector2(-138, 130)))

	# --- CLUSTER 2: lounge (back-right). Two chairs reading at each other with
	#     a table between - a conversational group, not two lonely chairs.
	out.append(rug(Vector2(118, 116)))
	out.append(armchair(Vector2(84, 112), -0.6))
	out.append(armchair(Vector2(152, 112), 2.6))
	out.append(side_table(Vector2(118, 134)))

	# A classmate seated at the back-left inner desk (reads as a peer, grounds
	# the room as "in session").
	out.append(Props.poly(Props.ellipse(11, 9, 14), Palette.INK, Vector2(-50, 40), 5))
	out.append(soft_shadow(12, 6, Vector2(-50, 52), 0.20))

	out.append(classroom_life(w, h))

	# Tall props the player can step behind: (node, front-edge_y in zone coords).
	depth.append({"node": plinth, "y": -h * 0.5 + 77})
	depth.append({"node": board, "y": -h * 0.5 + 76})
	depth.append({"node": nook_shelf, "y": 92})
	depth.append({"node": plant_tl, "y": -h * 0.5 + 115})
	depth.append({"node": plant_tr, "y": -h * 0.5 + 115})
	var n := group(out)
	n.name = "Decor"
	n.set_meta("depth_pairs", depth)
	return n

## Round rug - grounds a seating cluster on the floor plate.
static func rug(pos: Vector2) -> Node2D:
	var r := Props.poly(Props.ellipse(46, 34, 16), Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.35), Vector2.ZERO, 0)
	var n := group([r])
	n.position = pos
	return n

## Top-down armchair. `aim` = radians the seat faces (0 faces down-screen).
static func armchair(pos: Vector2, aim: float) -> Node2D:
	var back := _rrect(26, 9, 3, Palette.INK, Vector2(0, -10))
	var seat := Props.poly(Props.rounded_rect(26, 22, 7, 8), Palette.LIGHT, Vector2.ZERO, 1)
	var cushion := Props.poly(Props.rounded_rect(18, 15, 6, 8), Palette.SUNK, Vector2.ZERO, 2)
	var side_l := _rrect(5, 22, 2, Palette.BLUE, Vector2(-11, 1))
	var side_r := _rrect(5, 22, 2, Palette.BLUE, Vector2(11, 1))
	var n := group([back, seat, cushion, side_l, side_r])
	n.rotation = aim
	n.position = pos
	return n

## Small side / coffee table for seating clusters.
static func side_table(pos: Vector2) -> Node2D:
	var n := group([_rrect(18, 18, 5, Palette.LIGHT, Vector2.ZERO), _rrect(14, 14, 4, Palette.PAPER, Vector2.ZERO, 1)])
	n.position = pos
	return n

## Standing floor lamp: lamp pool on the floor, thin stem, warm bulb.
static func floor_lamp(pos: Vector2) -> Node2D:
	var pool := Props.poly(Props.ellipse(30, 22, 14), Color(1.0, 0.86, 0.62, 0.14), Vector2(0, 8), 0)
	var base := _rrect(12, 12, 4, Palette.INK, Vector2(0, 6))
	var stem := Props.poly(Props.bar(2, 22), Palette.SUNK, Vector2(0, -2), 2)
	var bulb := Props.poly(Props.ellipse(5, 5, 10), Palette.GOLD, Vector2(0, -14), 3)
	var n := group([pool, base, stem, bulb])
	n.position = pos
	return n

## Ambient life for the lecture hall: a ticking clock and drifting dust motes.
## Motion is eased (sin-drift and a smoothed per-second hand) so it reads
## organic rather than robotic constant-speed.
static func classroom_life(w: float, h: float) -> Life:
	var life := Life.new()
	life.name = "Life"

	var clock := Node2D.new()
	clock.name = "Clock"
	clock.position = Vector2(w * 0.5 - 74, -h * 0.5 + 26)
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
	life.second = second

	var dust := Node2D.new()
	dust.name = "Dust"
	life.add_child(dust)
	for i in 3:
		var mote := Node2D.new()
		mote.name = "Mote%d" % i
		var base_x: float = -50 + i * 30
		var base_y: float = -h * 0.5 + 22 + i
		mote.position = Vector2(base_x, base_y)
		var dot := Props.poly(Props.ellipse(2.2, 2.2, 5), Palette.PAPER, Vector2.ZERO, 8)
		dot.modulate.a = 0.5
		mote.add_child(dot)
		dust.add_child(mote)
		life._motes.append([mote, base_x, base_y, float(i) * TAU / 3.0])
	return life

## Drives the eased ambient life in the lecture hall.
class Life:
	extends Node2D
	var t := 0.0
	var second: Polygon2D
	var _motes: Array = []   # [node, base_x, base_y, phase]

	func _process(delta: float) -> void:
		t += delta
		if second:
			# Second hand: eased snap toward each new second (accelerate/brake),
			# never a flat constant spin.
			var target: float = int(t) * TAU / 60.0
			var k: float = clampf(1.0 - pow(0.5, delta * 6.0), 0.0, 1.0)
			second.rotation = lerp_angle(second.rotation, target, k)
		for m in _motes:
			var mote: Node2D = m[0]
			mote.position.y = m[2] + sin(t * 1.4 + m[3]) * 5.0
			mote.position.x = m[1] + cos(t * 0.6 + m[3]) * 8.0

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
