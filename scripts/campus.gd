extends Node2D
## Campus hub: the single walkable map with 6 zones.
## The world, zones and HUD are all built in code (placeholder shapes only).

const WORLD_W := 2400.0
const WORLD_H := 1800.0

# zone_key -> {pos (centre), size, label, color}
const ZONE_DEFS := {
    "lecture":   {"pos": Vector2(450, 400),   "size": Vector2(360, 260), "label": "Lecture Hall",        "color": Color("#004b8d")},
    "library":   {"pos": Vector2(1950, 400),  "size": Vector2(360, 260), "label": "The Spiral Library",  "color": Color("#004b8d")},
    "cafeteria": {"pos": Vector2(450, 1400),  "size": Vector2(360, 260), "label": "Food Hall",           "color": Color("#004b8d")},
    "flat":      {"pos": Vector2(1950, 1400), "size": Vector2(360, 260), "label": "Dorm Flat",           "color": Color("#004b8d")},
    "clubroom":  {"pos": Vector2(1650, 900),  "size": Vector2(360, 260), "label": "MUITSA Clubroom",     "color": Color("#4A148C")},
    "exam":      {"pos": Vector2(1200, 250),  "size": Vector2(360, 240), "label": "Exam Hall",           "color": Color("#4789C8")},
}

@onready var player: CharacterBody2D = $Player
var current_zone := ""
var popup: PanelContainer
var prompt_lbl: Label
var toast_lbl: Label
var day_lbl: Label
var slot_dots: Array = []
var bars := {}

func _ready() -> void:
    _build_world()
    _build_zones()
    _build_hud()
    _setup_camera()

    # Spawn the player midpoint of the quad.
    player.global_position = Vector2(1200, 950)

    # Listen for zone enter/exit (zones set GameState.current_zone).
    GameState.meters_changed.connect(_refresh_hud)
    GameState.day_changed.connect(_refresh_hud)
    _refresh_hud()

## Ground + a lighter central quad walkway.
func _build_world() -> void:
    var ground := Polygon2D.new()
    ground.polygon = PackedVector2Array([
        Vector2.ZERO, Vector2(WORLD_W, 0), Vector2(WORLD_W, WORLD_H), Vector2(0, WORLD_H)])
    ground.color = Color("#0A2240")
    add_child(ground)

    var quad := Polygon2D.new()
    quad.polygon = PackedVector2Array([
        Vector2(850, 750), Vector2(1550, 750), Vector2(1550, 1050), Vector2(850, 1050)])
    quad.color = Color("#123a6b")
    add_child(quad)

## A zone = Area2D + collision rect + coloured plate + label sign.
func _build_zones() -> void:
    for key in ZONE_DEFS:
        var def: Dictionary = ZONE_DEFS[key]
        var zone := Area2D.new()
        zone.name = key.capitalize()
        zone.position = def["pos"]

        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = def["size"]
        shape.shape = rect
        zone.add_child(shape)

        var plate := Polygon2D.new()
        plate.polygon = PackedVector2Array([
            Vector2(-def["size"].x / 2, -def["size"].y / 2),
            Vector2(def["size"].x / 2, -def["size"].y / 2),
            Vector2(def["size"].x / 2, def["size"].y / 2),
            Vector2(-def["size"].x / 2, def["size"].y / 2)])
        plate.color = def["color"]
        zone.add_child(plate)

        var sign := Label.new()
        sign.text = def["label"]
        sign.position = Vector2(-200, -def["size"].y / 2 - 34)
        sign.size = Vector2(400, 30)
        sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sign.add_theme_font_size_override("font_size", 17)
        sign.add_theme_color_override("font_color", Color("#e4a024"))
        zone.add_child(sign)

        add_child(zone)
        zone.body_entered.connect(_on_zone_entered.bind(key))
        zone.body_exited.connect(_on_zone_exited.bind(key))

func _on_zone_entered(body: Node2D, key: String) -> void:
    if body == player:
        current_zone = key

func _on_zone_exited(_body: Node2D, key: String) -> void:
    if current_zone == key:
        current_zone = ""

## Top HUD: day, three meter bars, slot dots, menu button, prompt, toast.
func _build_hud() -> void:
    var ui := CanvasLayer.new()
    ui.layer = 10
    add_child(ui)

    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.size = Vector2(420, 152)
    panel.add_theme_stylebox_override("panel", _panel_style())
    ui.add_child(panel)
    var vbox := VBoxContainer.new()
    vbox.position = Vector2(16, 16)
    panel.add_child(vbox)

    day_lbl = Label.new()
    day_lbl.add_theme_font_size_override("font_size", 20)
    day_lbl.add_theme_color_override("font_color", Color("#e4a024"))
    vbox.add_child(day_lbl)

    bars["energy"] = _make_bar("ENERGY", Color("#25AAE1"), vbox)
    bars["stress"] = _make_bar("STRESS", Color("#e4a024"), vbox)
    bars["gpa"] = _make_bar("GPA", Color("#4789C8"), vbox)

    # Slot dots: three squares showing how many of today's actions are spent.
    var slots_row := HBoxContainer.new()
    slots_row.add_theme_constant_override("separation", 6)
    for i in GameState.SLOTS_PER_DAY:
        var dot := ColorRect.new()
        dot.custom_minimum_size = Vector2(22, 22)
        dot.color = Color("#1b4a80")
        slots_row.add_child(dot)
        slot_dots.append(dot)
    vbox.add_child(slots_row)

    var menu_btn := Button.new()
    menu_btn.text = "Quit to menu"
    menu_btn.position = Vector2(16, 180)
    menu_btn.pressed.connect(_on_menu)
    ui.add_child(menu_btn)

    # "Press E" prompt that appears when standing in a zone.
    prompt_lbl = Label.new()
    prompt_lbl.position = Vector2(0, 640)
    prompt_lbl.size = Vector2(1280, 40)
    prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_lbl.add_theme_font_size_override("font_size", 20)
    prompt_lbl.add_theme_color_override("font_color", Color("#e4a024"))
    ui.add_child(prompt_lbl)

    # Toast for messages ("Assignment late! GPA -10" and friends).
    toast_lbl = Label.new()
    toast_lbl.position = Vector2(240, 260)
    toast_lbl.size = Vector2(800, 60)
    toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_lbl.add_theme_font_size_override("font_size", 22)
    toast_lbl.add_theme_color_override("font_color", Color("#ffffff"))
    ui.add_child(toast_lbl)

    # Action chooser popup (hidden until you press E in a zone).
    popup = PanelContainer.new()
    popup.anchor_left = 0.5
    popup.anchor_top = 0.5
    popup.anchor_right = 0.5
    popup.anchor_bottom = 0.5
    popup.offset_left = -260
    popup.offset_top = -150
    popup.offset_right = 260
    popup.offset_bottom = 150
    popup.process_mode = Node.PROCESS_MODE_ALWAYS
    popup.add_theme_stylebox_override("panel", _panel_style())
    popup.hide()
    ui.add_child(popup)
    _build_popup_children()

func _panel_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.04, 0.11, 0.22, 0.94)
    s.border_color = Color("#e4a024")
    s.set_border_width_all(2)
    s.set_corner_radius_all(6)
    return s

func _make_bar(label: String, col: Color, parent: Node) -> ProgressBar:
    var hb := HBoxContainer.new()
    var name_lbl := Label.new()
    name_lbl.text = label
    name_lbl.custom_minimum_size = Vector2(70, 0)
    name_lbl.add_theme_font_size_override("font_size", 13)
    name_lbl.add_theme_color_override("font_color", Color("#c9d8ee"))
    hb.add_child(name_lbl)

    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(280, 18)
    bar.min_value = 0.0
    bar.max_value = GameState.GPA_MAX
    bar.show_percentage = false
    bar.add_theme_stylebox_override("background", _bar_bg_style())
    parent.add_child(hb)
    hb.add_child(bar)
    return bar

func _bar_bg_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#0c1e38")
    s.set_corner_radius_all(4)
    return s

func _build_popup_children() -> void:
    # Populated at open-time; here we just give it a static skeleton.
    var box := VBoxContainer.new()
    box.name = "PopBox"
    box.set_anchors_preset(Control.PRESET_FULL_RECT)
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 12)
    popup.add_child(box)

    var title := Label.new()
    title.name = "Title"
    title.text = ""
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("#e4a024"))
    box.add_child(title)

    var options_box := VBoxContainer.new()
    options_box.name = "Options"
    options_box.add_theme_constant_override("separation", 10)
    box.add_child(options_box)

func _setup_camera() -> void:
    var cam := player.get_node_or_null("Camera2D") as Camera2D
    if cam == null:
        return
    cam.limit_left = 0
    cam.limit_top = 0
    cam.limit_right = int(WORLD_W)
    cam.limit_bottom = int(WORLD_H)

## Poll zone + interact input each frame; refresh the dynamic HUD bits.
func _process(_delta: float) -> void:
    if not GameState.has_run_started:
        return
    if current_zone != "" and not popup.visible:
        var zone_name: String = ZONE_DEFS[current_zone]["label"]
        var opts: Array = GameState.zone_options(current_zone)
        if opts.size() == 0:
            prompt_lbl.text = ""
        else:
            prompt_lbl.text = "Press E  -  %s" % zone_name
        if Input.is_action_just_pressed("interact") and opts.size() > 0:
            _open_popup(current_zone)
    elif current_zone == "":
        prompt_lbl.text = ""

func _open_popup(zone: String) -> void:
    var opts: Array = GameState.zone_options(zone)
    if opts.is_empty():
        return
    var box: VBoxContainer = popup.get_node("PopBox")
    var title: Label = box.get_node("Title")
    title.text = ZONE_DEFS[zone]["label"]
    var options_box: VBoxContainer = box.get_node("Options")
    for child in options_box.get_children():
        options_box.remove_child(child)
        child.queue_free()
    for opt in opts:
        var btn := Button.new()
        btn.text = opt["label"]
        btn.custom_minimum_size = Vector2(440, 44)
        btn.add_theme_font_size_override("font_size", 16)
        btn.pressed.connect(_choose_option.bind(zone, opt["id"]))
        options_box.add_child(btn)
    popup.show()
    get_tree().paused = true

func _choose_option(zone: String, opt_id: String) -> void:
    popup.hide()
    get_tree().paused = false
    var minigame: String = GameState.perform_option(zone, opt_id)
    if minigame != "":
        get_tree().change_scene_to_file(minigame)
    else:
        _maybe_leave()
        _refresh_hud()

func _maybe_leave() -> void:
    var next := GameState.next_scene_after_action()
    if next != "res://scenes/campus.tscn":
        get_tree().change_scene_to_file(next)

func _refresh_hud() -> void:
    day_lbl.text = "Day %d/%d - %s  (%d of %d slots used)" % [
        GameState.day, GameState.GAME_DAYS, GameState.slot_name(),
        GameState.slots_used, GameState.SLOTS_PER_DAY]
    bars["energy"].value = GameState.energy
    bars["stress"].value = GameState.stress
    bars["gpa"].value = GameState.gpa
    for i in GameState.SLOTS_PER_DAY:
        slot_dots[i].color = Color("#e4a024") if i < GameState.slots_used else Color("#1b4a80")
    # Flash the assignment/library reminder on due days.
    if GameState.day in GameState.ASSIGN_DAYS and not GameState.assignments_done.get(GameState.day, false):
        toast_lbl.text = "Today: an assignment is DUE at the library!"
    elif GameState.day == 7 and not GameState.exam_taken:
        toast_lbl.text = "FINALS DAY. Get to the Exam Hall!"
    elif GameState.toast_message != "":
        toast_lbl.text = GameState.toast_message
    else:
        toast_lbl.text = ""

func _on_menu() -> void:
    get_tree().paused = false
    GameState.has_run_started = false
    GameState.last_result = {}
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")