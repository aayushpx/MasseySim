extends Node
## Chip/layout audit: captures the real window (root viewport) in several states so
## we can verify every text-backing chip sizes to content, stays centred, and
## keeps sane padding. SubViewport captures hide draw_string text, so we must
## use the real window. Run: godot --path . res://tests/chip_audit.tscn --quit-after 1000 --display-driver x11

var campus: Node
var player: Node2D
var ui_layer: CanvasLayer

func _capture(name: String, clean: bool = false) -> void:
	if clean:
		for n in campus.get_children():
			if n == ui_layer or (n is CanvasLayer and n.layer >= 10):
				continue
			n.visible = false
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/opencode/chip_%s.png" % name)
	var pc: Control = campus.get("prompt_chip")
	var tc: Control = campus.get("toast_chip")
	var anchors := ""
	for n in ui_layer.get_children():
		var id := ""
		if n is PanelContainer:
			id = "panel"
		elif n is Button:
			id = "btn'%s'" % n.text
		elif n == pc:
			id = "prompt"
		elif n == tc:
			id = "toast"
		if id != "":
			anchors += " | %s rect=%s" % [id, n.get_global_rect()]
	print("cap %s | visible=%s%s | prompt size=%s text='%s' | toast size=%s text='%s'" % [
		name, get_viewport().get_visible_rect(), anchors,
		pc.size, pc.get("text"), tc.size, tc.get("text")])

func _ready() -> void:
	get_window().position = Vector2i(200, 100)
	get_window().size = Vector2i(1280, 720)
	GameState.start_run("Computer Science")
	campus = load("res://scenes/campus.tscn").instantiate()
	add_child(campus)
	for i in 10:
		await get_tree().process_frame
	for layer in campus.get_children():
		if layer is CanvasLayer and layer.layer == 10:
			ui_layer = layer
			break
	for i in 5:
		await get_tree().process_frame
	player = campus.get_node("Player")
	player.global_position = Vector2(450, 520)
	for i in 140:
		await get_tree().process_frame
	await _capture("A")
	await _capture("Aclean", true)
	GameState.day = 3
	campus.call("_refresh_hud")
	for i in 2:
		await get_tree().process_frame
	await _capture("B")
	await _capture("Bclean", true)
	player.global_position = Vector2(1200, 500)
	campus.set("current_zone", "clubroom")
	for i in 10:
		await get_tree().process_frame
	await _capture("C")
	print("CHIP AUDIT: DONE")
	get_tree().quit(0)