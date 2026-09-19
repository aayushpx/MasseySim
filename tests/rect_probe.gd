extends SceneTree
func _initialize() -> void:
	mute_audio()
	root.size = Vector2i(1280, 720)
	var sel: Node = load("res://scenes/degree_select.tscn").instantiate()
	root.add_child(sel)
	await process_frame
	await process_frame
	await process_frame
	print("== degree card rect probe @ window %s ==" % root.size)
	var centre: VBoxContainer = null
	for child in sel.get_children():
		if child is VBoxContainer:
			centre = child
	if centre == null:
		print("NO VBOX found")
		quit(1)
	print("centre VBox pos=%s size=%s" % [centre.position, centre.size])
	for i in centre.get_child_count():
		var c := centre.get_child(i)
		if c is Button:
			print("card [%s] text='%s' size=%s pos=%s" % [c.name, c.text, c.size, c.position])
			for j in c.get_child_count():
				var b := c.get_child(j)
				if b is VBoxContainer:
					print("    box size=%s pos=%s" % [b.size, b.position])
					for k in b.get_child_count():
						var lbl: Control = b.get_child(k)
						print("    %s text='%s' size=%s pos=%s min=%s wrap=%s" % [
							lbl.name, lbl.text, lbl.size, lbl.position, lbl.get_combined_minimum_size(),
							lbl.get("autowrap_mode")])
	var base := UiKit.label("Computer Science", 20, Palette.PAPER, true, 700)
	root.add_child(base)
	await process_frame
	print("lbl base        min=%s" % base.get_combined_minimum_size())
	base.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	await process_frame
	print("lbl wrap        min=%s" % base.get_combined_minimum_size())
	base.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	await process_frame
	print("lbl wrap+ovr    min=%s" % base.get_combined_minimum_size())
	quit(0)

func mute_audio() -> void:
	AudioServer.set_bus_mute(0, true)