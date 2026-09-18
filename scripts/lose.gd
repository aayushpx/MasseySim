extends Control
## LOSE: "Dropped Out" screen with the reason + retry.

const GOLD := Color("#e4a024")
const RED := Color("#d64848")
const LIGHT := Color("#4789C8")
const WHITE := Color("#f0f5ff")
const DARK := Color("#0A2240")

func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = DARK
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var title := Label.new()
    title.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title.position = Vector2(0, 90)
    title.text = "DROPPED OUT"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 52)
    title.add_theme_color_override("font_color", RED)
    add_child(title)

    var tag := Label.new()
    tag.set_anchors_preset(Control.PRESET_TOP_WIDE)
    tag.position = Vector2(0, 160)
    var tagline := "The degree has been returned to sender."
    if GameState.last_result.get("kind", "") == "noshow":
        tagline = "Finals: didn't attend. The degree filed a missing persons report."
    tag.text = tagline
    tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tag.add_theme_font_size_override("font_size", 20)
    tag.add_theme_color_override("font_color", LIGHT)
    add_child(tag)

    var reason := Label.new()
    reason.set_anchors_preset(Control.PRESET_CENTER)
    reason.anchor_left = 0.5
    reason.anchor_right = 0.5
    reason.offset_left = -460
    reason.offset_right = 460
    reason.offset_top = 230
    reason.offset_bottom = 310
    reason.text = GameState.lost_reason
    reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    reason.add_theme_font_size_override("font_size", 20)
    reason.add_theme_color_override("font_color", WHITE)
    add_child(reason)

    var again := Button.new()
    again.text = "RETRY - pick a degree"
    again.set_anchors_preset(Control.PRESET_CENTER)
    again.anchor_left = 0.5
    again.anchor_right = 0.5
    again.offset_left = -180
    again.offset_right = 180
    again.offset_top = 370
    again.custom_minimum_size = Vector2(360, 56)
    again.add_theme_font_size_override("font_size", 20)
    again.pressed.connect(_on_again)
    add_child(again)

    var menu := Button.new()
    menu.text = "MAIN MENU"
    menu.set_anchors_preset(Control.PRESET_CENTER)
    menu.anchor_left = 0.5
    menu.anchor_right = 0.5
    menu.offset_left = -180
    menu.offset_right = 180
    menu.offset_top = 442
    menu.custom_minimum_size = Vector2(360, 48)
    menu.pressed.connect(_on_menu)
    add_child(menu)

func _on_again() -> void:
    get_tree().change_scene_to_file("res://scenes/degree_select.tscn")

func _on_menu() -> void:
    GameState.has_run_started = false
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")