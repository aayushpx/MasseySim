extends Node
## Dev probe: renders win.tscn / lose.tscn inside a 1280x720 SubViewport
## (the game's declared base resolution) and also into the live window,
## waits out the pop-in tweens, then prints each Control's global rect and
## captures a PNG per variant so layout can be verified against both the
## 720 target and the WM's actual window.
## Run: godot --path . res://tests/end_screen_probe.tscn --quit-after 3200 --display-driver x11 --resolution 1280x720

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	var sub := SubViewport.new()
	sub.size = Vector2i(1280, 720)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	add_child(sub)

	GameState.gpa = 72.0
	GameState.degree = "Computer Science"
	GameState.lost_reason = "Burnout. The stress topped 100 and so did you (metaphorically)."
	GameState.last_result = {"kind": "stress"}

	await _probe("res://scenes/win.tscn", "win", sub)
	await _probe("res://scenes/lose.tscn", "lose", sub)

	print("END SCREEN PROBE: DONE")
	get_tree().quit(0)

func _probe(scene_path: String, tag: String, sub: SubViewport) -> void:
	var root: Control = load(scene_path).instantiate()
	sub.add_child(root)
	for i in 4:
		await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw

	print("== %s (sub viewport 1280x720) ==" % tag)
	print("  root rect=%s" % [root.get_global_rect()])
	for c in root.get_children():
		if c is Control:
			print("  %-22s rect=%s" % [c.name, (c as Control).get_global_rect()])
	var img := sub.get_texture().get_image()
	img.save_png("/tmp/opencode/end720_%s.png" % tag)
	print("  captured end720_%s.png" % tag)

	root.queue_free()
	await get_tree().process_frame