extends Control
## Main menu: title screen with a Start button. All UI built in code so the
## .tscn stays tiny.

func _ready() -> void:
    # Background: Massey Dark Blue.
    var bg := ColorRect.new()
    bg.color = Color("#0A2240")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var centre := VBoxContainer.new()
    centre.set_anchors_preset(Control.PRESET_CENTER)
    centre.position = Vector2(-260, -180)
    centre.size = Vector2(520, 360)
    centre.alignment = BoxContainer.ALIGNMENT_CENTER
    centre.add_theme_constant_override("separation", 18)
    add_child(centre)

    var title := Label.new()
    title.text = "MASSEY UNI SIMULATOR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 40)
    title.add_theme_color_override("font_color", Color("#e4a024"))
    centre.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Survive 7 days. Don't drop out. Try to graduate."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("#4789C8"))
    centre.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 24)
    centre.add_child(spacer)

    var start_btn := Button.new()
    start_btn.text = "START SEMESTER"
    start_btn.custom_minimum_size = Vector2(260, 56)
    start_btn.add_theme_font_size_override("font_size", 24)
    start_btn.pressed.connect(_on_start)
    centre.add_child(start_btn)

    var controls := Label.new()
    controls.text = "Move: WASD / Arrows  |  Interact: E / Space\nTalk to the zones, survive the sem."
    controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls.add_theme_font_size_override("font_size", 15)
    controls.add_theme_color_override("font_color", Color("#9fb6d4"))
    centre.add_child(controls)

    var footer := Label.new()
    footer.text = "A fan-made parody for MUITSA Game Making Hackathon 2026."
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 12)
    footer.add_theme_color_override("font_color", Color("#5f7ca6"))
    centre.add_child(footer)

func _on_start() -> void:
    get_tree().change_scene_to_file("res://scenes/degree_select.tscn")