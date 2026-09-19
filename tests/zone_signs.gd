extends Node
## Zone-sign text audit: for each of the 6 zones, teleport the player to the
## zone centre, wait for the camera to settle, capture the real window and
## report the on-screen rect of the zone sign. SubViewport captures hide
## Label/draw_string text in some configs, so use the real window.
## Run: godot --path . res://tests/zone_signs.tscn --quit-after 1000 --display-driver x11

const ZONES := {
	"lecture": Vector2(450, 400),
	"library": Vector2(1950, 400),
	"cafeteria": Vector2(450, 1400),
	"flat": Vector2(1950, 1400),
	"clubroom": Vector2(1650, 900),
	"exam": Vector2(1200, 230),
}

var campus: Node
var player: Node2D

func _capture(name: String, cam_center: Vector2) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/opencode/sign_%s.png" % name)
	# Expected sign screen rect (logical): world (zone.x, zone.y - 190)
	var sign_world: Vector2 = ZONES[name] + Vector2(0, -190)
	var half := get_viewport().get_visible_rect().size * 0.5
	var sign_screen: Vector2 = sign_world - cam_center + half
	print("sign %-10s world=%s cam=%s screen=%s" % [name, sign_world, cam_center, sign_screen])

func _ready() -> void:
	get_window().position = Vector2i(200, 100)
	get_window().size = Vector2i(1280, 720)
	GameState.start_run("Computer Science")
	campus = load("res://scenes/campus.tscn").instantiate()
	add_child(campus)
	for i in 10:
		await get_tree().process_frame
	player = campus.get_node("Player")
	var cam: Camera2D = campus.get("cam")
	cam.position_smoothing_enabled = false
	for i in 60:
		await get_tree().process_frame
	for key in ZONES:
		var target: Vector2 = ZONES[key]
		player.global_position = target
		for i in 8:
			await get_tree().process_frame
		var cc: Vector2 = cam.get_screen_center_position()
		await _capture(key, cc)
	print("ZONE SIGNS: DONE")
	get_tree().quit(0)