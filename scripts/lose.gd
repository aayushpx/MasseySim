extends Control
## LOSE: "Dropped Out" screen with the reason + retry.
## The headline lands like a stamp: scaled, rotated, then slammed straight.

func _ready() -> void:
    theme = UiKit.theme()
    UiKit.backdrop(self, Color(0.14, 0.03, 0.05, 1.0))
    AudioFx.sfx("wrong")

    var title := UiKit.label("DROPPED OUT", 58, Palette.RED, true, 800)
    title.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title.position = Vector2(0, 80)
    add_child(title)
    _stamp_in(title)

    var tag_lbl := UiKit.label("", 20, Palette.LIGHT, false, 600)
    tag_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
    tag_lbl.position = Vector2(0, 158)
    if GameState.last_result.get("kind", "") == "noshow":
        tag_lbl.text = "Finals: didn't attend. The degree filed a missing persons report."
    else:
        tag_lbl.text = "The degree has been returned to sender."
    add_child(tag_lbl)
    UiKit.pop_in(tag_lbl, 0.25)

    var reason := UiKit.label(GameState.lost_reason, 19, Palette.PAPER, false, 500)
    reason.anchor_left = 0.5
    reason.anchor_right = 0.5
    reason.anchor_top = 0.0
    reason.anchor_bottom = 0.0
    reason.offset_left = -460
    reason.offset_right = 460
    reason.offset_top = 224
    reason.offset_bottom = 318
    reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(reason)
    UiKit.pop_in(reason, 0.4)

    var again := UiKit.button("RETRY - pick a degree", Vector2(360, 56), 20, 700, true)
    again.anchor_left = 0.5
    again.anchor_right = 0.5
    again.anchor_top = 0.0
    again.anchor_bottom = 0.0
    again.offset_left = -180
    again.offset_right = 180
    again.offset_top = 348
    again.pressed.connect(_on_again)
    add_child(again)
    UiKit.pop_in(again, 0.6)

    var menu := UiKit.button("MAIN MENU", Vector2(360, 46), 17, 600)
    menu.anchor_left = 0.5
    menu.anchor_right = 0.5
    menu.anchor_top = 0.0
    menu.anchor_bottom = 0.0
    menu.offset_left = -180
    menu.offset_right = 180
    menu.offset_top = 424
    menu.pressed.connect(_on_menu)
    add_child(menu)
    UiKit.pop_in(menu, 0.75)

    UiKit.fade_in(self)

## Stamp-like reveal: tilted, oversized, then slammed flat with a shake.
func _stamp_in(node: Control) -> void:
    node.pivot_offset = node.size * 0.5
    node.scale = Vector2(1.5, 1.5)
    node.rotation = deg_to_rad(-5)
    node.modulate.a = 0.0
    var tw := node.create_tween()
    tw.tween_interval(0.2)
    tw.tween_property(node, "modulate:a", 1.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tw.tween_interval(0.1)
    tw.tween_property(node, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(node, "rotation", 0.0, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_callback(func() -> void: _thud())

func _thud() -> void:
    UiKit.flash(self, Palette.RED, 0.12)

func _on_again() -> void:
    UiKit.fade_and_switch(self, "res://scenes/degree_select.tscn")

func _on_menu() -> void:
    GameState.has_run_started = false
    UiKit.fade_and_switch(self, "res://scenes/main_menu.tscn")