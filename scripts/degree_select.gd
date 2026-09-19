extends Control
## Degree selection screen. Four degrees, one shared game underneath.
## Cards get per-degree accents and a small vector glyph.

const ACCENTS := {
    "Computer Science": Color("#25AAE1"),
    "Software Engineering": Color("#4789C8"),
    "Veterinary Science": Color("#7C3AED"),
    "Food Science": Color("#e4a024"),
}

func _ready() -> void:
    theme = UiKit.theme()
    UiKit.backdrop(self)
    AudioFx.music("menu")

    var centre := VBoxContainer.new()
    centre.set_anchors_preset(Control.PRESET_CENTER)
    centre.position = Vector2(-330, -210)
    centre.size = Vector2(660, 460)
    centre.alignment = BoxContainer.ALIGNMENT_CENTER
    centre.add_theme_constant_override("separation", 12)
    add_child(centre)

    var title := UiKit.label("CHOOSE YOUR DEGREE", 30, Palette.GOLD, true, 800)
    centre.add_child(title)

    var hint := UiKit.label("Same campus, same stress. The jokes change.", 15, Palette.LIGHT, false, 500)
    centre.add_child(hint)

    for degree in GameState.DEGREES:
        centre.add_child(_make_degree_card(degree))

    var back := UiKit.button("< Back", Vector2(200, 42), 16, 600)
    back.pressed.connect(_on_back)
    centre.add_child(back)

    UiKit.fade_in(self)

## One clickable degree card: accent stripe + name + blurb.
func _make_degree_card(degree_name: String) -> Button:
    var accent: Color = ACCENTS.get(degree_name, Palette.GOLD)

    var btn := UiKit.button("", Vector2(560, 64), 20, 700)
    var normal := UiKit.box(Color("#0d2b52"), 12, accent, 2)
    btn.add_theme_stylebox_override("normal", normal)
    btn.add_theme_stylebox_override("hover", UiKit.box(accent, 12))
    btn.add_theme_stylebox_override("pressed", UiKit.box(Palette.GOLD, 12))
    btn.add_theme_color_override("font_color", Palette.PAPER)
    btn.add_theme_color_override("font_hover_color", Palette.DARK)
    btn.add_theme_color_override("font_pressed_color", Palette.DARK)

    # Card body: title + blurb stacked, inset so wrapped text respects the
    # rounded border instead of bleeding to the card edges.
    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_FULL_RECT)
    box.offset_left = 16
    box.offset_right = -16
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 2)

    var name_lbl := UiKit.label(degree_name, 20, Palette.PAPER, true, 700)
    name_lbl.custom_minimum_size = Vector2(560, 30)
    name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    box.add_child(name_lbl)
    var blurb_lbl := UiKit.label(GameState.DEGREES[degree_name], 13, Palette.FOG, false, 500)
    blurb_lbl.custom_minimum_size = Vector2(560, 19)
    blurb_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    blurb_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    blurb_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    box.add_child(blurb_lbl)

    btn.add_child(box)
    # Re-tint title text on hover via font_hover_color already set on btn; the
    # inner labels use their own colours, so tint them through the button too.
    name_lbl.add_theme_color_override("font_color", Palette.PAPER)
    btn.mouse_entered.connect(func() -> void: name_lbl.add_theme_color_override("font_color", Palette.DARK))
    btn.mouse_exited.connect(func() -> void: name_lbl.add_theme_color_override("font_color", Palette.PAPER))

    btn.pressed.connect(_on_pick.bind(degree_name))
    return btn

func _on_pick(degree_name: String) -> void:
    UiKit.fade_and_switch(self, "res://scenes/campus.tscn", GameState.start_run.bind(degree_name))

func _on_back() -> void:
    UiKit.fade_and_switch(self, "res://scenes/main_menu.tscn")