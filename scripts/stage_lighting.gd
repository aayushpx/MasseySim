class_name StageLights
## Real 2D lighting rigs (Light2D + occluders) for the campus zones.
## Prototype applies only to the lecture hall; the rig generates a soft
## radial falloff texture at runtime so no PNG assets are needed.
## Requires the Forward+ / Mobile renderer (Compatibility ignores Light2D).

const RADIAL_SIZE := 256

static var _radial_tex: GradientTexture2D

## A soft radial intensity texture for PointLight2D (white core -> transparent).
static func radial_texture() -> GradientTexture2D:
	if _radial_tex != null:
		return _radial_tex
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = grad
	t.width = RADIAL_SIZE
	t.height = RADIAL_SIZE
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 1.0)
	_radial_tex = t
	return t

## Build a single soft point light.
static func point(light_color: Color, energy: float, pos: Vector2, scale: float = 1.0, z: int = 0) -> PointLight2D:
	var l := PointLight2D.new()
	l.name = "PointLight"
	l.color = light_color
	l.energy = energy
	l.position = pos
	l.z_index = z
	l.texture = radial_texture()
	l.texture_scale = scale
	l.shadow_enabled = true
	l.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5
	l.shadow_filter_smooth = 3.0
	l.shadow_color = Color(0.02, 0.05, 0.09, 1.0)
	return l

## A closed-rect occluder (for desks, shelves, walls).
static func occ_rect(w: float, h: float, pos: Vector2, z: int = 0) -> LightOccluder2D:
	var poly := OccluderPolygon2D.new()
	poly.polygon = Props.rounded_rect(w, h, minf(w, h) * 0.5, 4)
	poly.closed = true
	var o := LightOccluder2D.new()
	o.name = "Occluder"
	o.position = pos
	o.z_index = z
	o.occluder = poly
	return o

## A round occluder (plants, people).
static func occ_circle(r: float, pos: Vector2, z: int = 0) -> LightOccluder2D:
	var poly := OccluderPolygon2D.new()
	poly.polygon = Props.ellipse(r, r, 16)
	poly.closed = true
	var o := LightOccluder2D.new()
	o.name = "Occluder"
	o.position = pos
	o.z_index = z
	o.occluder = poly
	return o

## Lecture hall lighting rig: a warm overhead lamp + a cooler daylight spill
## near the front board wall, with occluders on the furniture so the pools
## actually wrap the room (real depth, not a flat tint).
static func classroom(w: float, h: float) -> Node2D:
	var rig := Node2D.new()
	rig.name = "StageLights"

	# Warm overhead / lamp pool: sits above the desks, reads as tungsten.
	rig.add_child(point(Color(1.0, 0.86, 0.62), 0.55, Vector2(0, -18), 2.6))

	# Cool daylight spill pooling in from the front wall (near the board).
	rig.add_child(point(Color(0.62, 0.78, 1.0), 0.5, Vector2(0, -h * 0.5 + 26), 2.3))

	# --- Occluders (mirror the lecture_hall furniture layout) ---
	# Front board wall + lectern stand cast a strong line.
	rig.add_child(occ_rect(w - 40, 36, Vector2(0, -h * 0.5 + 60)))
	rig.add_child(occ_rect(150, 86, Vector2(0, -h * 0.5 + 34)))

	# Three rows of desks -> one long slab per row.
	for r in 3:
		rig.add_child(occ_rect(w - 60, 26, Vector2(0, -h * 0.5 + 128 + r * 44)))

	# Bookshelves along the side walls.
	rig.add_child(occ_rect(66, 152, Vector2(w * 0.5 - 34, 0)))
	rig.add_child(occ_rect(66, 152, Vector2(-w * 0.5 + 34, 0)))

	# Plants in the front corners.
	rig.add_child(occ_circle(12, Vector2(-w * 0.5 + 22, -h * 0.5 + 110)))
	rig.add_child(occ_circle(12, Vector2(w * 0.5 - 22, -h * 0.5 + 110)))
	return rig