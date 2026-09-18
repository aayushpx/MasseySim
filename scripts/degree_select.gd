extends Control
## Degree selection screen. Four degrees, one shared game underneath.
## Each degree only changes flavour text + one small event + the ending blurb.

const PALETTE := {
    "cs":   Color("#25AAE1"),
    "se":   Color("#4789C8"),
    "vet":  Color("#7C3AED"),
    "food": Color("#e4a024"),
}

func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0A2240")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var centre := VBoxContainer.new()
    centre.set_anchors_preset(Control.PRESET_CENTER)
    centre.position = Vector2(-330, -210)
    centre.size = Vector2(660, 420)
    centre.alignment = BoxContainer.ALIGNMENT_CENTER
    centre.add_theme_constant_override("separation", 12)
    add_child(centre)

    var title := Label.new()
    title.text = "CHOOSE YOUR DEGREE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("#e4a024"))
    centre.add_child(title)

    var hint := Label.new()
    hint.text = "Same campus, same stress. The jokes change."
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_color_override("font_color", Color("#4789C8"))
    centre.add_child(hint)

    for degree in GameState.DEGREES:
        centre.add_child(_make_degree_card(degree))

    var back := Button.new()
    back.text = "< Back"
    back.custom_minimum_size = Vector2(200, 40)
    back.pressed.connect(_on_back)
    centre.add_child(back)

## Build one clickable degree card row.
func _make_degree_card(degree_name: String) -> Button:
    var card := Button.new()
    card.custom_minimum_size = Vector2(560, 62)
    var accent: Color = PALETTE["food"]
    if degree_name == "Computer Science":
        accent = PALETTE["cs"]
    elif degree_name == "Software Engineering":
        accent = PALETTE["se"]
    elif degree_name == "Veterinary Science":
        accent = PALETTE["vet"]

    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_FULL_RECT)
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 2)

    var name_lbl := Label.new()
    name_lbl.text = degree_name
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_lbl.add_theme_font_size_override("font_size", 20)
    name_lbl.add_theme_color_override("font_color", Color("#ffffff"))

    var blurb_lbl := Label.new()
    blurb_lbl.text = GameState.DEGREES[degree_name]
    blurb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    blurb_lbl.add_theme_font_size_override("font_size", 13)
    blurb_lbl.add_theme_color_override("font_color", Color("#c9d8ee"))

    box.add_child(name_lbl)
    box.add_child(blurb_lbl)
    card.add_child(box)
    card.add_theme_color_override("font_color", accent)
    card.pressed.connect(_on_pick.bind(degree_name))
    return card

func _on_pick(degree_name: String) -> void:
    GameState.start_run(degree_name)
    get_tree().change_scene_to_file("res://scenes/campus.tscn")

func _on_back() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")