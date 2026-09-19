extends Node
## Dev screenshot harness: renders the campus inside a 1280x720 SubViewport
## with its own harness-controlled Camera2D and captures four poses directly
## from the SubViewport texture (no window/movie-writer involvement, so framing
## is exact and window-aspect-independent).
## Run: godot --path . res://tests/shot_tool.tscn --quit-after 900 --display-driver x11

var player: Node2D
var campus: Node
var hcam: Camera2D
var sub: SubViewport
var fmark: Polygon2D
var t0: int

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	GameState.start_run("Computer Science")

	sub = SubViewport.new()
	sub.size = Vector2i(1280, 720)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	add_child(sub)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.1)
	bg.size = Vector2(1280, 720)
	sub.add_child(bg)

	campus = load("res://scenes/campus.tscn").instantiate()
	sub.add_child(campus)
	for i in 4:
		await get_tree().process_frame

	player = campus.get_node("Player")
	fmark = _add_marker(Vector2(0, 0), Color(0, 1, 0), "Mfollow")
	_add_marker(Vector2(450, 382), Color(1, 0, 1), "Mwarm_magenta")
	hcam = Camera2D.new()
	hcam.name = "HarnessCam"
	campus.add_child(hcam)
	hcam.position_smoothing_enabled = false
	hcam.make_current()
	hcam.limit_left = -4000
	hcam.limit_top = -4000
	hcam.limit_right = 8000
	hcam.limit_bottom = 8000
	player.get_node("PlayerCam").enabled = false
	t0 = Time.get_ticks_msec()

	await _pose(Vector2(1200, 980), "", "1_overview_morning", 2.0)
	await _pose(Vector2(450, 520), "lecture", "2_lecture_front_morning", 3.0)
	await _pose(Vector2(280, 460), "lecture", "3_lecture_behind_shelf", 4.0)
	GameState.slots_used = 2
	campus.mod.color = Palette.TINT_EVENING
	await _pose(Vector2(450, 520), "lecture", "4_lecture_front_evening", 5.0)

	print("SHOT TOOL: DONE")
	get_tree().quit(0)

func _pose(pos: Vector2, zone: String, name: String, at_s: float) -> void:
	player.global_position = pos
	fmark.position = pos
	campus.current_zone = zone
	hcam.position = pos
	while sub.get_camera_2d() != hcam:
		hcam.make_current()
		await get_tree().process_frame
	var wait := (t0 + int(at_s * 1000.0) + 300) - Time.get_ticks_msec()
	if wait > 0:
		await get_tree().create_timer(wait / 1000.0).timeout
	await RenderingServer.frame_post_draw
	print("pose %s origin=%s active=%s" % [name, sub.get_canvas_transform().origin, (sub.get_camera_2d().name if sub.get_camera_2d() else "none")])
	var img := sub.get_texture().get_image()
	img.save_png("/tmp/opencode/h_%s.png" % name)
	print("captured h_%s.png" % name)

func _add_marker(pos: Vector2, col: Color, mname: String) -> Polygon2D:
	var m := Polygon2D.new()
	m.color = col
	m.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6)])
	m.name = mname
	m.position = pos
	m.z_index = 10
	campus.add_child(m)
	return m