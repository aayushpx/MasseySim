class_name UiKit
## Shared UI atoms and juice helpers for the flat-vector "academic poster" look.
## One style language for every screen: Massey palette, Fraunces for display,
## Work Sans for body, gold buttons, rounded boxes, glow backdrops, and a few
## cheap screen-feel primitives (fade-in, pops, flashes, confetti). Fonts are
## the only external assets and are OFL-licensed (see ASSETS.md).

static var _theme: Theme

## The single Theme used by every screen. Default font = Work Sans so all text
## inherits it; display text opts into Fraunces via label(..., display=true).
static func theme() -> Theme:
	if _theme != null:
		return _theme
	var th := Theme.new()
	th.default_font = CampusDecor.body_font(500)
	th.default_font_size = 16

	th.set_stylebox("panel", "PanelContainer", box(Color(0.02, 0.06, 0.13, 0.93), 12, Palette.GOLD, 1))
	th.set_color("font_color", "Label", Palette.PAPER)
	th.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	th.set_constant("shadow_offset_y", "Label", 1)

	th.set_stylebox("normal", "Button", box(Palette.GOLD, 12))
	th.set_stylebox("hover", "Button", box(Palette.BRIGHT, 12))
	th.set_stylebox("pressed", "Button", box(Palette.BLUE, 12))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Palette.DARK)
	th.set_color("font_hover_color", "Button", Palette.DARK)
	th.set_color("font_pressed_color", "Button", Palette.PAPER)
	th.set_color("font_focus_color", "Button", Palette.DARK)
	_theme = th
	return _theme

## Rounded flat box with optional border.
static func box(col: Color, radius: float = 12.0, border: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	if border_w > 0:
		s.border_color = border
		s.set_border_width_all(border_w)
	return s

## A Label styled for this art direction.
static func label(text: String, size: int = 16, col: Color = Palette.PAPER,
		display: bool = false, weight: int = 600, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", CampusDecor.display_font(weight) if display else CampusDecor.body_font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

## A Button styled as a flat rounded key. Plays hover + click SFX.
static func button(text: String, min_size: Vector2 = Vector2(0, 0), size: int = 18,
		weight: int = 600, display: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	if min_size.x > 0 or min_size.y > 0:
		b.custom_minimum_size = min_size
	b.add_theme_font_override("font", CampusDecor.display_font(weight) if display else CampusDecor.body_font(weight))
	b.add_theme_font_size_override("font_size", size)
	b.mouse_entered.connect(func() -> void: AudioFx.sfx("hover"))
	b.pressed.connect(func() -> void: AudioFx.sfx("click"))
	return b

## Full-rect soft radial backdrop (reuses the world glow shader, re-tinted for
## screen space). Adds the base Massey dark fill behind it.
static func backdrop(parent: Control, center: Color = Color(0.03, 0.09, 0.20, 1.0), edge: Color = Color(0.012, 0.03, 0.06, 1.0)) -> void:
	var base := ColorRect.new()
	base.color = edge
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(base)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/world_glow.gdshader")
	mat.set_shader_parameter("col_center", center)
	mat.set_shader_parameter("col_edge", edge)
	mat.set_shader_parameter("uvc", Vector2(0.5, 0.42))
	glow.material = mat
	parent.add_child(glow)

## One-shot fade-in from the ink tone at the start of any screen.
static func fade_in(parent: Node) -> void:
	var cover := ColorRect.new()
	cover.color = Palette.INK
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 99
	layer.add_child(cover)
	parent.add_child(layer)
	var tw := cover.create_tween()
	tw.tween_property(cover, "modulate:a", 0.0, 0.35)
	tw.tween_callback(layer.queue_free)

## Pop-in scale+tween for titles and stamps.
static func pop_in(node: Control, delay: float = 0.0) -> void:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(1.15, 1.15)
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(node, "modulate:a", 1.0, 0.25)
	tw.tween_property(node, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Full-screen flash on a high layer (red for hits, white for goals).
static func flash(parent: Node, col: Color, strength: float = 0.4) -> void:
	var rect := ColorRect.new()
	rect.color = col
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = strength
	var layer := CanvasLayer.new()
	layer.layer = 98
	layer.add_child(rect)
	parent.add_child(layer)
	var tw := rect.create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, 0.30)
	tw.tween_callback(layer.queue_free)

## Fade to ink, then switch scenes. Optional hook fires at fade start
## (e.g. starting the run). Callable should take zero args.
static func fade_and_switch(parent: Node, scene_path: String, hook: Callable = Callable()) -> void:
	if hook.is_valid():
		hook.call()
	var tree := parent.get_tree()
	var rect := ColorRect.new()
	rect.color = Palette.INK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	var layer := CanvasLayer.new()
	layer.layer = 99
	layer.add_child(rect)
	parent.add_child(layer)
	var tw := rect.create_tween()
	tw.tween_property(rect, "modulate:a", 1.0, 0.22)
	tw.tween_callback(func() -> void: tree.change_scene_to_file(scene_path))

## Small particle burst at a screen-space point (world or UI layer).
static func burst(parent: Node, at: Vector2, col: Color, count: int = 10) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = count
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 130.0
	p.gravity = Vector2(0, 120.0)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.8
	var g := Gradient.new()
	g.colors = [col, col, Color(col.r, col.g, col.b, 0.0)]
	p.color_ramp = g
	parent.add_child(p)
	var tw := p.create_tween()
	tw.tween_callback(p.queue_free).set_delay(0.8)

## Endless confetti rain for the win screen.
static func confetti(layer: CanvasLayer, count: int = 70) -> void:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.amount = count
	p.lifetime = 6.0
	p.one_shot = false
	p.explosiveness = 0.1
	p.position = Vector2(640, 720)
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.gravity = Vector2(0, 120.0)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 240.0
	p.speed_scale = 1.4
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var g := Gradient.new()
	g.colors = [Palette.GOLD, Palette.BRIGHT, Palette.PURPLE, Palette.LIGHT, Palette.SAGE]
	p.color_ramp = g
	layer.add_child(p)
