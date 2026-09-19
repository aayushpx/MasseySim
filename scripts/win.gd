extends Control
## WIN: Graduation screen. Shown when the exam is passed with GPA >= 55.
## Real confetti rain, gold title pop-in, styled buttons.

const ENDING_BLURBS := {
    "Computer Science": "You graduate with a CS degree and a toaster-load of debugging war stories.",
    "Software Engineering": "You graduate in Software Engineering with an unshakable faith in stand-ups.",
    "Veterinary Science": "You graduate in Veterinary Science. The llamas finally accept you as an honourary member.",
    "Food Science": "You graduate in Food Science. The pavlova judges have spoken: DELICIOUS.",
}

func _ready() -> void:
    theme = UiKit.theme()
    UiKit.backdrop(self, Color(0.06, 0.10, 0.22, 1.0))

    var title := UiKit.label("YOU GRADUATED!", 58, Palette.GOLD, true, 800)
    title.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title.position = Vector2(0, 70)
    add_child(title)
    UiKit.pop_in(title, 0.15)

    var gpa_lbl := UiKit.label("Final GPA: %.0f  -  pass line was 55." % GameState.gpa, 24, Palette.LIGHT, false, 600)
    gpa_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
    gpa_lbl.position = Vector2(0, 158)
    add_child(gpa_lbl)
    UiKit.pop_in(gpa_lbl, 0.35)

    var blurb := UiKit.label(ENDING_BLURBS.get(GameState.degree, "You did it!"), 20, Palette.PAPER, false, 500)
    blurb.anchor_left = 0.5
    blurb.anchor_right = 0.5
    blurb.anchor_top = 0.0
    blurb.anchor_bottom = 0.0
    blurb.offset_left = -400
    blurb.offset_right = 400
    blurb.offset_top = 224
    blurb.offset_bottom = 304
    blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(blurb)
    UiKit.pop_in(blurb, 0.5)

    var again := UiKit.button("PLAY AGAIN - new degree", Vector2(360, 56), 20, 700, true)
    again.anchor_left = 0.5
    again.anchor_right = 0.5
    again.anchor_top = 0.0
    again.anchor_bottom = 0.0
    again.offset_left = -180
    again.offset_right = 180
    again.offset_top = 336
    again.pressed.connect(_on_again)
    add_child(again)
    UiKit.pop_in(again, 0.7)

    var menu := UiKit.button("MAIN MENU", Vector2(360, 46), 17, 600)
    menu.anchor_left = 0.5
    menu.anchor_right = 0.5
    menu.anchor_top = 0.0
    menu.anchor_bottom = 0.0
    menu.offset_left = -180
    menu.offset_right = 180
    menu.offset_top = 412
    menu.pressed.connect(_on_menu)
    add_child(menu)
    UiKit.pop_in(menu, 0.85)

    var confetti_layer := CanvasLayer.new()
    confetti_layer.layer = 60
    add_child(confetti_layer)
    UiKit.confetti(confetti_layer)
    AudioFx.sfx("confirm")

    UiKit.fade_in(self)

func _on_again() -> void:
    UiKit.fade_and_switch(self, "res://scenes/degree_select.tscn")

func _on_menu() -> void:
    GameState.has_run_started = false
    UiKit.fade_and_switch(self, "res://scenes/main_menu.tscn")