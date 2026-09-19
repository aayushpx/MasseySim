extends Node2D
## Campus hub: the single walkable map with 6 zones, now rendered as a flat
## vector "academic poster" composition - glowing ground, themed floors with
## dressing props, styled HUD with vector meter icons, time-of-day tinting,
## vignette, moment shake and a day-transition wipe.

const WORLD_W := 2400.0
const WORLD_H := 1800.0
const TINT_TWEEN := 0.6
const PLAYER_Z := 8
const DEPTH_BEHIND := 12

# zone_key -> {pos, size, label, floor tone, decor builder name}
const ZONE_DEFS := {
    "lecture":   {"pos": Vector2(450, 400),   "size": Vector2(380, 280), "label": "Lecture Hall",        "floor": Palette.BLUE,        "decor": "lecture"},
    "library":   {"pos": Vector2(1950, 400),  "size": Vector2(380, 280), "label": "The Spiral Library",  "floor": Color("#143a6b"),    "decor": "library"},
    "cafeteria": {"pos": Vector2(450, 1400),  "size": Vector2(380, 280), "label": "Food Hall",           "floor": Color("#e7ddc6"),   "decor": "cafeteria"},
    "flat":      {"pos": Vector2(1950, 1400), "size": Vector2(380, 280), "label": "Dorm Flat",           "floor": Color("#e6d9bd"),   "decor": "flat"},
    "clubroom":  {"pos": Vector2(1650, 900),  "size": Vector2(380, 280), "label": "MUITSA Clubroom",     "floor": Palette.PURPLE_DARK, "decor": "clubroom"},
    "exam":      {"pos": Vector2(1200, 230),  "size": Vector2(380, 260), "label": "Exam Hall",           "floor": Color("#0b2a50"),   "decor": "exam"},
}

@onready var player: CharacterBody2D = $Player
var current_zone := ""
var popup: PanelContainer
var prompt_chip: PromptChip
var toast_chip: PromptChip
var day_lbl: Label
var slot_lbl: Label
var wipe: ColorRect
var wipe_lbl: Label
var metered := {}        # "energy" -> MeterRow
var fx_layer: CanvasLayer
var slot_pills := []
var mod: CanvasModulate
var _tint_tween: Tween
var cam: Camera2D
var _last_day := -1
var _prev_meters := {"energy": 70.0, "stress": 30.0, "gpa": 60.0}
var _depth_zones := {}   # zone_key -> {zone, pairs: [{node, y}]}

func _ready() -> void:
    _build_ground()
    _build_pathways()
    _build_zones()
    _build_hud()
    _setup_camera()
    AudioFx.music("campus")

    GameState.meters_changed.connect(_refresh_hud)
    GameState.day_changed.connect(_refresh_hud)
    refresh_now()
    _refresh_hud()

func _process(_delta: float) -> void:
    if not GameState.has_run_started:
        _apply_slot_tint(Palette.TINT_MORNING)
        return
    _update_depth()
    if current_zone != "" and not popup.visible:
        var zone_name: String = ZONE_DEFS[current_zone]["label"]
        var opts: Array = GameState.zone_options(current_zone)
        if opts.is_empty():
            prompt_chip.text = ""
        else:
            prompt_chip.text = "Press E  -  %s" % zone_name
        if Input.is_action_just_pressed("interact") and opts.size() > 0:
            _open_popup(current_zone)
    elif current_zone == "":
        prompt_chip.text = ""

## Cheap Billboard-style depth: inside a depth zone the player lifts above the
## decor, and each tall prop flips on top of the player when its front edge is
## below the player's feet (player walks "behind" it). Resets outside the zone.
func _update_depth() -> void:
    var active: bool = current_zone != "" and _depth_zones.has(current_zone)
    var pz: int = PLAYER_Z if active else 0
    if player.z_index != pz:
        player.z_index = pz
    for key in _depth_zones:
        var entry: Dictionary = _depth_zones[key]
        var zone: Node2D = entry["zone"]
        var base_y: float = zone.global_position.y
        for pair in entry["pairs"]:
            var node: Node2D = pair["node"]
            var z: int = 0
            if active and key == current_zone:
                z = DEPTH_BEHIND if player.global_position.y < base_y + float(pair["y"]) else 0
            if node.z_index != z:
                node.z_index = z

# --- World ---------------------------------------------------------------

func _build_ground() -> void:
    # Glowing ground: a soft radial gradient, deeper at the world edges.
    var glow := ColorRect.new()
    glow.name = "Ground"
    glow.position = Vector2.ZERO
    glow.size = Vector2(WORLD_W, WORLD_H)
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var mat := ShaderMaterial.new()
    mat.shader = load("res://assets/shaders/world_glow.gdshader")
    glow.material = mat
    add_child(glow)

    # A faint grid of lawn stripes for depth (very subtle).
    for i in 6:
        var stripe := Polygon2D.new()
        stripe.polygon = PackedVector2Array([
            Vector2(200.0 + i * 200.0, 0), Vector2(200.0 + i * 200.0 + 70, 0),
            Vector2(200.0 + i * 200.0 + 70, WORLD_H), Vector2(200.0 + i * 200.0, WORLD_H)])
        stripe.color = Color(1.0, 1.0, 1.0, 0.02)
        add_child(stripe)

func _build_pathways() -> void:
    # Central plus-shaped walkways (rectangular strips in the ground tone).
    var strips := [
        [Vector2(560, 900), Vector2(1880, 900), 46.0],
        [Vector2(1200, 330), Vector2(1200, 1470), 46.0],
    ]
    for s in strips:
        var a: Vector2 = s[0]
        var b: Vector2 = s[1]
        var w: float = s[2]
        var line := Line2D.new()
        line.width = w
        line.default_color = Color(1.0, 1.0, 1.0, 0.05)
        line.add_point(a)
        line.add_point(b)
        add_child(line)

    # Fountain at the quad centre.
    var f := Props.poly(Props.ellipse(46, 46, 24), Palette.LIGHT, Vector2(1200, 900))
    add_child(f)
    var f2 := Props.poly(Props.ellipse(30, 30, 20), Palette.BRIGHT, Vector2(1200, 900), 1)
    add_child(f2)
    var f3 := Props.poly(Props.ellipse(16, 16, 16), Palette.DARK, Vector2(1200, 900), 2)
    add_child(f3)

# --- Zones (floor plate + collision + dressing + sign) ------------------

func _build_zones() -> void:
    for key in ZONE_DEFS:
        var def: Dictionary = ZONE_DEFS[key]
        var zone := Area2D.new()
        zone.name = key.capitalize()
        zone.position = def["pos"]
        add_child(zone)

        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = def["size"]
        shape.shape = rect
        zone.add_child(shape)

        var w: float = def["size"].x
        var h: float = def["size"].y

        # Floor plate: rounded, slightly offset shadow + the plate itself.
        var shadow := Props.poly(Props.rounded_rect(w + 8, h + 8, 18, 6), Color(0.0, 0.0, 0.0, 0.35), Vector2(4, 6))
        zone.add_child(shadow)
        var plate := Props.poly(Props.rounded_rect(w, h, 18), def["floor"])
        zone.add_child(plate)

        # Dressing (drawn above the plate).
        var decor := _zone_decor(key, w, h)
        if decor != null:
            zone.add_child(decor)

        # Classroom prototype: real Light2D rig + walk-behind-tall-props depth.
        if key == "lecture":
            zone.add_child(StageLights.classroom(w, h))
            _depth_zones[key] = {"zone": zone, "pairs": decor.get_meta("depth_pairs", [])}

        # Sign chip above the door line.
        zone.add_child(_make_sign(key, def["label"]))
        zone.add_child(_make_door(key, w, h))

        zone.body_entered.connect(_on_zone_entered.bind(key))
        zone.body_exited.connect(_on_zone_exited.bind(key))

func _on_zone_entered(body: Node2D, key: String) -> void:
    if body == player:
        current_zone = key

func _on_zone_exited(_body: Node2D, key: String) -> void:
    if current_zone == key:
        current_zone = ""

func _make_sign(key: String, label: String) -> Node2D:
    var holder := Node2D.new()
    holder.position = Vector2(0, -190)
    var pill := Props.poly(Props.rounded_rect(360, 40, 12), Palette.INK, Vector2.ZERO, 1)
    holder.add_child(pill)
    var cap := Props.poly(Props.rounded_rect(356, 36, 11), Palette.BLUE, Vector2.ZERO, 2)
    holder.add_child(cap)
    var stroke := Props.poly(Props.rounded_rect(352, 32, 10), Palette.DARK, Vector2.ZERO, 3)
    stroke.modulate.a = 0.9
    holder.add_child(stroke)
    var lbl := Label.new()
    lbl.text = label
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lbl.position = Vector2(-180, -20)
    lbl.size = Vector2(360, 40)
    lbl.add_theme_font_override("font", CampusDecor.display_font(700))
    lbl.add_theme_font_size_override("font_size", 21)
    lbl.add_theme_color_override("font_color", Palette.GOLD if _is_club(key) else Palette.PAPER)
    lbl.add_theme_constant_override("outline_size", 3)
    lbl.add_theme_color_override("font_outline_color", Palette.INK)
    lbl.z_index = 4
    holder.add_child(lbl)
    return holder

func _make_door(key: String, w: float, h: float) -> Node2D:
    var holder := Node2D.new()
    holder.position = Vector2(0, -h * 0.5 + 12)
    var col := Palette.GOLD if _is_club(key) else Palette.PAPER
    var door := Props.poly(Props.rounded_rect(54, 16, 6), Color(1.0, 1.0, 1.0, 0.10))
    door.color = Color(1, 1, 1, 0.12)
    holder.add_child(door)
    var knob := Props.poly(Props.ellipse(4, 4, 10), col, Vector2(16, 0), 1)
    holder.add_child(knob)
    return holder

func _is_club(key: String) -> bool:
    return key == "clubroom"

func _zone_decor(key: String, w: float, h: float) -> Node2D:
    match key:
        "lecture":
            return CampusDecor.lecture_hall(w, h)
        "library":
            var out: Array = []
            out.append(CampusDecor.bookshelf(Vector2(-w * 0.5 + 40, 0), 66, 160, 4))
            out.append(CampusDecor.bookshelf(Vector2(w * 0.5 - 40, 0), 66, 160, 4))
            out.append(CampusDecor.reading_table(Vector2(-90, -40), 66))
            out.append(CampusDecor.reading_table(Vector2(30, -40), 66))
            out.append(CampusDecor.reading_table(Vector2(-60, 60), 66))
            out.append(CampusDecor.reading_table(Vector2(70, 60), 66))
            out.append(CampusDecor.plant(Vector2(-w * 0.5 + 30, h * 0.5 - 34)))
            out.append(CampusDecor.plant(Vector2(w * 0.5 - 30, h * 0.5 - 34)))
            return CampusDecor.group(out)
        "cafeteria":
            var out: Array = []
            out.append(CampusDecor.cafe_counter(Vector2(-120, -h * 0.5 + 60), 150))
            out.append(CampusDecor.cafe_counter(Vector2(120, -h * 0.5 + 60), 90))
            out.append(CampusDecor.reading_table(Vector2(0, 20), 130))
            out.append(CampusDecor.reading_table(Vector2(-120, 110), 130))
            out.append(CampusDecor.reading_table(Vector2(120, 110), 130))
            out.append(CampusDecor._text("TODAY'S SPECIAL: THE MEME SANDWICH (back by popular despair)", Vector2(-w * 0.5 + 30, -h * 0.5 + 28), 10, Palette.FOG, false, 600))
            return CampusDecor.group(out)
        "flat":
            var out: Array = []
            out.append(CampusDecor.bed(Vector2(-110, 0), 120))
            out.append(CampusDecor.bed(Vector2(120, 0), 120))
            out.append(CampusDecor.bookshelf(Vector2(-w * 0.5 + 34, -h * 0.5 + 70), 52, 110, 3))
            out.append(CampusDecor.reading_table(Vector2(0, 100), 90))
            out.append(CampusDecor._text("FLAT BULLETIN: NAP, EAT, REPEAT.", Vector2(w * 0.5 - 185, -h * 0.5 + 30), 10, Palette.FOG, false, 600))
            return CampusDecor.group(out)
        "clubroom":
            var out: Array = []
            out.append(CampusDecor.banner(Vector2(0, -70), 260, 86))
            out.append(CampusDecor.reading_table(Vector2(-110, 70), 80))
            out.append(CampusDecor.reading_table(Vector2(110, 70), 80))
            out.append(CampusDecor.plant(Vector2(-w * 0.5 + 32, -h * 0.5 + 30)))
            out.append(CampusDecor.plant(Vector2(w * 0.5 - 32, -h * 0.5 + 30)))
            return CampusDecor.group(out)
        "exam":
            var out: Array = []
            out.append(CampusDecor.exam_rows(Vector2(0, -30), w, 6))
            var clock_lbl := CampusDecor._text("FINALS WEEK. NO WIFI. ONLY CONSEQUENCES.", Vector2(-150, -h * 0.5 + 18), 14, Palette.FOG, false, 700)
            out.append(clock_lbl)
            var indent := Props.poly(Props.rounded_rect(120, 40, 8), Palette.INK, Vector2(0, -h * 0.5 + 52))
            out.append(indent)
            var seat := Props.poly(Props.ellipse(22, 22, 14), Palette.GOLD, Vector2(0, -h * 0.5 + 52), 1)
            out.append(seat)
            return CampusDecor.group(out)
    return null

# --- HUD -----------------------------------------------------------------

func _build_hud() -> void:
    var ui := CanvasLayer.new()
    ui.layer = 10
    add_child(ui)

    # --- Left panel: day + meters + slots.
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.add_theme_stylebox_override("panel", _panel_style())
    ui.add_child(panel)
    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 8)
    panel.add_child(vbox)

    var head := HBoxContainer.new()
    head.add_theme_constant_override("separation", 10)
    day_lbl = Label.new()
    day_lbl.add_theme_font_override("font", CampusDecor.display_font(800))
    day_lbl.add_theme_font_size_override("font_size", 26)
    day_lbl.add_theme_color_override("font_color", Palette.GOLD)
    head.add_child(day_lbl)
    slot_lbl = Label.new()
    slot_lbl.add_theme_font_override("font", CampusDecor.body_font(600))
    slot_lbl.add_theme_font_size_override("font_size", 13)
    slot_lbl.add_theme_color_override("font_color", Palette.FOG)
    slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    head.add_child(slot_lbl)
    vbox.add_child(head)

    for key in ["energy", "stress", "gpa"]:
        var row := MeterRow.new()
        row.setup(key)
        vbox.add_child(row)
        metered[key] = row

    # Slot pills (Morning / Afternoon / Evening).
    var slots_row := HBoxContainer.new()
    slots_row.add_theme_constant_override("separation", 6)
    for i in GameState.SLOTS_PER_DAY:
        var pill := Control.new()
        pill.custom_minimum_size = Vector2(96, 20)
        pill.add_theme_font_override("font", CampusDecor.body_font(600))
        pill.add_theme_font_size_override("font_size", 11)
        pill.draw.connect(_draw_pill.bind(i, pill))
        slots_row.add_child(pill)
        slot_pills.append(pill)
    vbox.add_child(slots_row)

    # Quit button (chip-backed so it stays readable over open art).
    var quit := Button.new()
    quit.text = "Menu"
    quit.add_theme_font_override("font", CampusDecor.body_font(500))
    quit.add_theme_font_size_override("font_size", 12)
    quit.add_theme_color_override("font_color", Palette.FOG)
    quit.add_theme_color_override("font_hover_color", Palette.GOLD)
    quit.position = Vector2(16, 330)
    quit.add_theme_stylebox_override("normal", PromptChip.chip_style())
    quit.add_theme_stylebox_override("hover", PromptChip.chip_style(0.95, true))
    quit.add_theme_stylebox_override("pressed", PromptChip.chip_style(0.95, true))
    quit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    quit.pressed.connect(_on_menu)
    ui.add_child(quit)

    # --- Prompt chip (bottom centre).
    prompt_chip = PromptChip.new()
    prompt_chip.center = Vector2(640, 690)
    prompt_chip.font_weight = 600
    prompt_chip.font_size = 18
    prompt_chip.text_color = Palette.GOLD
    ui.add_child(prompt_chip)

    # --- Toast.
    toast_chip = PromptChip.new()
    toast_chip.center = Vector2(640, 80)
    toast_chip.font_weight = 500
    toast_chip.font_size = 18
    toast_chip.text_color = Palette.PAPER
    ui.add_child(toast_chip)

    # --- Action popup.
    popup = PanelContainer.new()
    popup.anchor_left = 0.5
    popup.anchor_top = 0.5
    popup.anchor_right = 0.5
    popup.anchor_bottom = 0.5
    popup.offset_left = -280
    popup.offset_top = -170
    popup.offset_right = 280
    popup.offset_bottom = 170
    popup.process_mode = Node.PROCESS_MODE_ALWAYS
    popup.add_theme_stylebox_override("panel", _panel_style())
    popup.hide()
    ui.add_child(popup)
    _build_popup_children()

    # --- Day transition wipe.
    wipe = ColorRect.new()
    wipe.color = Color("#06152b")
    wipe.anchor_right = 1.0
    wipe.anchor_bottom = 1.0
    wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
    wipe.modulate.a = 0.0
    ui.add_child(wipe)
    wipe_lbl = Label.new()
    wipe_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wipe_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    wipe_lbl.anchor_right = 1.0
    wipe_lbl.anchor_bottom = 1.0
    wipe_lbl.position = Vector2(0, -40)
    wipe_lbl.add_theme_font_override("font", CampusDecor.display_font(700))
    wipe_lbl.add_theme_font_size_override("font_size", 72)
    wipe_lbl.add_theme_color_override("font_color", Palette.GOLD)
    wipe_lbl.modulate.a = 0.0
    ui.add_child(wipe_lbl)

    # --- Atmosphere: cinema pass (vignette + Massey grade + grain, world layer 5).
    var vig := ColorRect.new()
    vig.anchor_right = 1.0
    vig.anchor_bottom = 1.0
    vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var vmat := ShaderMaterial.new()
    vmat.shader = load("res://assets/shaders/cinema.gdshader")
    vig.material = vmat
    var vig_layer := CanvasLayer.new()
    vig_layer.layer = 5
    vig_layer.add_child(vig)
    add_child(vig_layer)

    # --- Juice: screen-space particle layer (above HUD art, below wipe).
    fx_layer = CanvasLayer.new()
    fx_layer.layer = 11
    add_child(fx_layer)

func _panel_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.02, 0.06, 0.13, 0.93)
    s.border_color = Palette.GOLD
    s.set_border_width_all(1)
    s.set_corner_radius_all(PromptChip.CHIP_RADIUS + 2)
    s.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
    s.shadow_size = 10
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 14
    s.content_margin_bottom = 14
    return s

func _draw_pill(ci: int, pill: Control) -> void:
    if pill.size.x <= 0:
        return
    var track := Rect2(Vector2(2, 2), pill.size - Vector2(4, 4))
    var names := ["MORNING", "AFTERNOON", "EVENING"]
    var fill := Palette.SUNK
    if ci < GameState.slots_used:
        fill = Palette.GOLD
    elif ci == GameState.slots_used:
        fill = Palette.BRIGHT
    var cap := StyleBoxFlat.new()
    cap.bg_color = fill
    cap.set_corner_radius_all(track.size.y * 0.5)
    pill.draw_style_box(cap, track)
    var f: Font = CampusDecor.body_font(700 if ci < GameState.slots_used or ci == GameState.slots_used else 600)
    var size := 10
    var ascend: float = f.get_ascent(size)
    var descend: float = f.get_descent(size)
    var baseline: float = (track.position.y + track.size.y * 0.5) + (ascend - descend) * 0.5
    var col := Palette.DARK if fill != Palette.SUNK else Palette.FOG
    pill.draw_string(f, Vector2(track.position.x, baseline), names[ci], HORIZONTAL_ALIGNMENT_CENTER, track.size.x, size, col)
    var outline := StyleBoxFlat.new()
    outline.draw_center = false
    outline.bg_color = Color.TRANSPARENT
    outline.border_color = Palette.PAPER
    outline.set_border_width_all(1)
    outline.set_corner_radius_all(track.size.y * 0.5)
    pill.draw_style_box(outline, track)

func _build_popup_children() -> void:
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
    title.add_theme_font_override("font", CampusDecor.display_font(700))
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", Palette.GOLD)
    box.add_child(title)

    var options_box := VBoxContainer.new()
    options_box.name = "Options"
    options_box.add_theme_constant_override("separation", 8)
    box.add_child(options_box)

func _setup_camera() -> void:
    var pj := player.cam_node as Camera2D
    if pj == null:
        return
    cam = pj
    cam.limit_left = 0
    cam.limit_top = 0
    cam.limit_right = int(WORLD_W)
    cam.limit_bottom = int(WORLD_H)

    # Atmosphere: time-of-day tinting.
    mod = CanvasModulate.new()
    mod.color = Palette.TINT_MORNING
    add_child(mod)

    refresh_now()

func refresh_now() -> void:
    if cam != null:
        cam.position_smoothing_speed = 6.0
    _apply_slot_tint(_slot_current_tint())

func _slot_current_tint() -> Color:
    if not GameState.has_run_started:
        return Palette.TINT_MORNING
    return Palette.slot_tint(GameState.slot_name())

func _apply_slot_tint(col: Color) -> void:
    if mod == null or mod.color.is_equal_approx(col):
        return
    if _tint_tween and _tint_tween.is_valid():
        _tint_tween.kill()
    _tint_tween = mod.create_tween()
    _tint_tween.tween_property(mod, "color", col, TINT_TWEEN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# --- Interaction ---------------------------------------------------------
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
        btn.custom_minimum_size = Vector2(460, 40)
        btn.add_theme_font_override("font", CampusDecor.body_font(500))
        btn.add_theme_font_size_override("font_size", 15)
        btn.add_theme_stylebox_override("normal", _btn_style(Palette.PURPLE_DARK if zone == "clubroom" else Palette.LIGHT))
        btn.add_theme_stylebox_override("hover", _btn_style(Palette.GOLD))
        btn.add_theme_stylebox_override("pressed", _btn_style(Palette.BLUE))
        btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        btn.add_theme_color_override("font_color", Palette.DARK)
        btn.add_theme_color_override("font_hover_color", Palette.DARK)
        btn.pressed.connect(_choose_option.bind(zone, opt["id"]))
        options_box.add_child(btn)
    popup.show()
    get_tree().paused = true
    AudioFx.sfx("select")
    _popup_enter_tween(popup)

func _btn_style(col: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = col
    s.set_corner_radius_all(PromptChip.CHIP_RADIUS)
    s.content_margin_left = PromptChip.PAD_X
    s.content_margin_right = PromptChip.PAD_X
    s.content_margin_top = PromptChip.PAD_Y
    s.content_margin_bottom = PromptChip.PAD_Y
    return s

func _popup_enter_tween(p: Control) -> void:
    p.modulate.a = 0.0
    p.scale = Vector2(0.92, 0.92)
    var tw := p.create_tween()
    tw.set_parallel(true)
    tw.tween_property(p, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tw.tween_property(p, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _choose_option(zone: String, opt_id: String) -> void:
    popup.hide()
    get_tree().paused = false
    var minigame: String = GameState.perform_option(zone, opt_id)
    if minigame != "":
        _fade_out_then(minigame)
    else:
        _maybe_leave()
        _refresh_hud()

func _fade_out_then(scene_path: String) -> void:
    var tw := create_tween()
    tw.tween_property(wipe, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    tw.tween_callback(func() -> void: get_tree().change_scene_to_file(scene_path))

func _maybe_leave() -> void:
    var next := GameState.next_scene_after_action()
    if next != "res://scenes/campus.tscn":
        _fade_out_then(next)

# --- Refresh -------------------------------------------------------------

func _refresh_hud() -> void:
    if not is_inside_tree():
        return
    var d: int = GameState.day
    day_lbl.text = "DAY %d" % d
    slot_lbl.text = GameState.slot_name().to_upper()
    for i in GameState.SLOTS_PER_DAY:
        if i < slot_pills.size():
            slot_pills[i].queue_redraw()

    # Meter tweens + feedback.
    for key in ["energy", "stress", "gpa"]:
        if not metered.has(key):
            continue
        var row: MeterRow = metered[key]
        var cur: float = row.value
        var target: float = GameState[key]
        if absf(target - cur) > 0.01:
            var tw := create_tween()
            tw.tween_method(row.set_value, cur, target, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        _meter_feedback(key, target - _prev_meters[key], row)

    # Toast logic (unchanged rules).
    if GameState.day in GameState.ASSIGN_DAYS and not GameState.assignments_done.get(GameState.day, false):
        toast_chip.text = "Today: an assignment is DUE at the library!"
    elif GameState.day == 7 and not GameState.exam_taken:
        toast_chip.text = "FINALS DAY. Get to the Exam Hall!"
    elif GameState.toast_message != "":
        toast_chip.text = GameState.toast_message
    else:
        toast_chip.text = ""

    if d != _last_day:
        _last_day = d
        if GameState.has_run_started:
            _day_wipe(d)

    _prev_meters = {"energy": GameState.energy, "stress": GameState.stress, "gpa": GameState.gpa}

func _meter_feedback(key: String, delta: float, row: MeterRow) -> void:
    if absf(delta) < 0.5:
        return
    if key == "gpa" and delta > 0.0:
        _sparkle(row.global_position + row.icon_pos() + Vector2(0, 8), Palette.GOLD)
    elif key == "stress" and delta > 0.0:
        _puff(row.global_position + row.icon_pos() + Vector2(0, 12), Palette.LIGHT)

var parts_active: Array = []
func _sparkle(at: Vector2, col: Color) -> void:
    _burst(at, col, 10)
func _puff(at: Vector2, col: Color) -> void:
    _burst(at, col, 6)

func _burst(at: Vector2, col: Color, count: int) -> void:
    if fx_layer == null:
        return
    var p := CPUParticles2D.new()
    p.position = at
    p.amount = count
    p.lifetime = 0.7
    p.one_shot = true
    p.explosiveness = 1.0
    p.emitting = true
    p.direction = Vector2(0, -1)
    p.spread = 180.0
    p.initial_velocity_min = 60.0
    p.initial_velocity_max = 140.0
    p.gravity = Vector2(0, 160.0)
    p.scale_amount_min = 1.0
    p.scale_amount_max = 2.0
    var grad := Gradient.new()
    grad.colors = [col, col, Color(col.r, col.g, col.b, 0.0)]
    p.color_ramp = grad
    fx_layer.add_child(p)
    parts_active.append(p)
    if parts_active.size() > 12:
        var old: Node = parts_active.pop_front()
        if is_instance_valid(old):
            old.queue_free()

func _day_wipe(day: int) -> void:
    wipe_lbl.text = "DAY %d" % day
    wipe.modulate.a = 1.0
    wipe_lbl.modulate = Color(1, 1, 1, 1)
    Fx.shake(cam, 5.0, 0.35)
    AudioFx.sfx("tick")
    var tw := create_tween()
    tw.tween_property(wipe_lbl, "modulate:a", 0.0, 0.8).set_delay(0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(wipe, "modulate:a", 0.0, 0.8).set_delay(0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tw.tween_callback(func() -> void: wipe_lbl.text = "")

func _on_menu() -> void:
    get_tree().paused = false
    GameState.has_run_started = false
    GameState.last_result = {}
    AudioFx.sfx("back")
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")