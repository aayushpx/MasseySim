extends Control
## WIN: Graduation screen. Shown when the exam is passed with GPA >= 55.

const GOLD := Color("#e4a024")
const LIGHT := Color("#4789C8")
const WHITE := Color("#f0f5ff")
const DARK := Color("#0A2240")

const ENDING_BLURBS := {
    "Computer Science": "You graduate with a CS degree and a toaster-load of debugging war stories.",
    "Software Engineering": "You graduate in Software Engineering with an unshakable faith in stand-ups.",
    "Veterinary Science": "You graduate in Veterinary Science. The llamas finally accept you as an honourary member.",
    "Food Science": "You graduate in Food Science. The pavlova judges have spoken: DELICIOUS.",
}

func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = DARK
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var title := Label.new()
    title.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title.position = Vector2(0, 80)
    title.text = "YOU GRADUATED!"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 54)
    title.add_theme_color_override("font_color", GOLD)
    add_child(title)

    var gpa_lbl := Label.new()
    gpa_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
    gpa_lbl.position = Vector2(0, 160)
    gpa_lbl.text = "Final GPA: %.0f  -  pass line was 55." % GameState.gpa
    gpa_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    gpa_lbl.add_theme_font_size_override("font_size", 24)
    gpa_lbl.add_theme_color_override("font_color", LIGHT)
    add_child(gpa_lbl)

    var blurb := Label.new()
    blurb.set_anchors_preset(Control.PRESET_CENTER)
    blurb.anchor_left = 0.5
    blurb.anchor_right = 0.5
    blurb.offset_left = -400
    blurb.offset_right = 400
    blurb.offset_top = 220
    blurb.offset_bottom = 300
    blurb.text = ENDING_BLURBS.get(GameState.degree, "You did it!")
    blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    blurb.add_theme_font_size_override("font_size", 20)
    blurb.add_theme_color_override("font_color", WHITE)
    add_child(blurb)

    var confetti := Label.new()
    confetti.set_anchors_preset(Control.PRESET_CENTER)
    confetti.anchor_left = 0.5
    confetti.anchor_right = 0.5
    confetti.offset_top = 320
    confetti.offset_left = -200
    confetti.offset_right = 200
    confetti.text = "confetti.  (placeholder confetti.)"
    confetti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    confetti.add_theme_font_size_override("font_size", 14)
    confetti.add_theme_color_override("font_color", Color("#5f7ca6"))
    add_child(confetti)

    var again := Button.new()
    again.text = "PLAY AGAIN - new degree"
    again.set_anchors_preset(Control.PRESET_CENTER)
    again.anchor_left = 0.5
    again.anchor_right = 0.5
    again.offset_left = -180
    again.offset_right = 180
    again.offset_top = 380
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
    menu.offset_top = 452
    menu.custom_minimum_size = Vector2(360, 48)
    menu.pressed.connect(_on_menu)
    add_child(menu)

func _on_again() -> void:
    get_tree().change_scene_to_file("res://scenes/degree_select.tscn")

func _on_menu() -> void:
    GameState.has_run_started = false
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")