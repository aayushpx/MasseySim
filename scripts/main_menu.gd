extends Control
## Main menu: flat-vector Massey title screen with glow backdrop,
## vector campus strip illustration, and a proper styled start button.

func _ready() -> void:
    theme = UiKit.theme()
    UiKit.backdrop(self)
    AudioFx.music("menu")

    var centre := VBoxContainer.new()
    centre.set_anchors_preset(Control.PRESET_CENTER)
    centre.position = Vector2(-260, -180)
    centre.size = Vector2(520, 380)
    centre.alignment = BoxContainer.ALIGNMENT_CENTER
    centre.add_theme_constant_override("separation", 14)
    add_child(centre)

    var title := UiKit.label("MASSEY UNI SIMULATOR", 46, Palette.GOLD, true, 800)
    title.add_theme_constant_override("shadow_offset_y", 3)
    centre.add_child(title)

    var subtitle := UiKit.label("Survive 7 days. Don't drop out. Try to graduate.", 16, Palette.LIGHT, false, 500)
    centre.add_child(subtitle)

    centre.add_child(Control.new()) # spacer

    var start := UiKit.button("START SEMESTER", Vector2(260, 58), 22, 700, true)
    start.pressed.connect(_on_start)
    centre.add_child(start)

    var controls := UiKit.label("Move: WASD / Arrows  |  Interact: E / Space\nTalk to the zones, survive the sem.", 13, Palette.FOG, false, 500)
    centre.add_child(controls)

    var footer := UiKit.label("UNOFFICIAL fan-made parody - not affiliated with Massey University or MUITSA.\nMade for the MUITSA Game Making Hackathon 2026. Music: Kevin MacLeod (CC BY 4.0), SFX: Kenney.nl (CC0).", 10, Palette.LIGHT, false, 500)
    footer.modulate.a = 0.55
    centre.add_child(footer)

    _draw_strip()
    UiKit.fade_in(self)

## Tiny flat-vector campus illustration strip at the bottom of the screen.
func _draw_strip() -> void:
    var base_y := 640.0
    var layer := CanvasLayer.new()
    layer.layer = 1
    add_child(layer)

    # Ground band.
    var ground := Props.poly(Props.rounded_rect(1260, 46, 8, 4), Palette.BLUE, Vector2(640, base_y))
    layer.add_child(ground)

    # Three small building silhouettes.
    var pos := [380.0, 620.0, 860.0]
    var widths := [80.0, 60.0, 74.0]
    var heights := [54.0, 74.0, 50.0]
    var cols := [Palette.DARK, Palette.LIGHT, Palette.DARK]
    for i in 3:
        var b := Props.poly(Props.rounded_rect(widths[i], heights[i], 6, 4),
                            cols[i], Vector2(pos[i], base_y - heights[i] * 0.5 - 4))
        layer.add_child(b)
        # tiny window dots
        for j in 2:
            var w := Props.poly(Props.ellipse(4, 4, 6), Palette.GOLD,
                                Vector2(pos[i] - widths[i] * 0.3 + j * widths[i] * 0.6,
                                        base_y - heights[i] * 0.5 - 4))
            w.modulate.a = 0.5
            layer.add_child(w)

    # Tiny player blob in centre.
    var player_blob := Props.poly(Props.ellipse(10, 10, 14), Palette.BRIGHT,
                                  Vector2(640, base_y - 8))
    layer.add_child(player_blob)

func _on_start() -> void:
    get_tree().change_scene_to_file("res://scenes/degree_select.tscn")
