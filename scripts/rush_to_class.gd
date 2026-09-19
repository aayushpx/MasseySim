extends Node2D
## RUSH TO CLASS: dodge minigame.
## Run up the quad to the Lecture Hall door while avoiding the campus geese.
## Geese are round flat-vector baddies with proper walks (sway + wing).
## Hits add Stress; getting there at all adds an on-time GPA bonus.
## Juice: hit-stop slow-mo + red flash + feather burst on contact, speed
## lines while running, gold burst + victory flash at the door.

const GOAL_Y := 80.0
const BOUNDS := {"x_min": 180.0, "x_max": 1100.0, "y_min": 40.0, "y_max": 600.0}

var player: CharacterBody2D
var hits := 0
var spawn_timer := 0.6
var geese: Array = []          # [{node: Node2D, sway: float}]
var hits_lbl: Label
var _time := 0.0
var _speed_lines: Array = []
var _hitstop := 0.0
var _done := false

func _ready() -> void:
    _build_world()
    _build_player()
    _build_hud()
    AudioFx.music("campus")
    UiKit.fade_in(self)

func _build_world() -> void:
    # Flat quad: dark ground with a luminous pathway up the middle.
    var bg := Props.poly(Props.rounded_rect(1280, 720, 0, 1), Palette.INK, Vector2(640, 360))
    add_child(bg)

    var path := Props.poly(Props.rounded_rect(940, 640, 18, 6), Palette.BLUE, Vector2(640, 360))
    path.modulate.a = 0.55
    add_child(path)

    var lane := Polygon2D.new()
    lane.polygon = PackedVector2Array([
        Vector2(140, 0), Vector2(1140, 0), Vector2(1100, 720), Vector2(180, 720)])
    lane.color = Color(1.0, 1.0, 1.0, 0.04)
    add_child(lane)

    # The Lecture Hall arch (gold) - the goal.
    var arch := Props.poly(Props.rounded_rect(190, 130, 40, 8), Palette.GOLD, Vector2(640, GOAL_Y + 26))
    add_child(arch)
    var arch_inner := Props.poly(Props.rounded_rect(160, 100, 34, 8), Palette.INK, Vector2(640, GOAL_Y + 26))
    add_child(arch_inner)

    var door_lbl := UiKit.label("LECTURE HALL", 15, Palette.GOLD, false, 700)
    door_lbl.position = Vector2(540, 18)
    door_lbl.size = Vector2(200, 26)
    add_child(door_lbl)

func _build_player() -> void:
    var packed := load("res://scenes/player.tscn") as PackedScene
    player = packed.instantiate() as CharacterBody2D
    player.speed = 320.0
    player.global_position = Vector2(640, 600)
    add_child(player)
    var cam := player.get_node_or_null("Camera2D") as Camera2D
    if cam != null:
        cam.enabled = false

func _build_hud() -> void:
    var ui := CanvasLayer.new()
    ui.layer = 50
    add_child(ui)

    var top := UiKit.label("THE BELL IS RINGING! Dodge the geese, reach the door!", 20, Palette.GOLD, false, 700)
    top.position = Vector2(0, 16)
    top.size = Vector2(1280, 40)
    ui.add_child(top)

    hits_lbl = UiKit.label("", 14, Palette.FOG, false, 500)
    hits_lbl.position = Vector2(0, 58)
    hits_lbl.size = Vector2(1280, 26)
    ui.add_child(hits_lbl)
    _update_hits_lbl()

func _process(delta: float) -> void:
    if _done:
        return
    _time += delta

    # Player speed -> spawn subtle speed lines.
    var player_speed := player.velocity.length()
    if player_speed > 140.0 and _speed_lines.size() < 10:
        _spawn_speed_line()

    player.global_position.x = clampf(player.global_position.x, BOUNDS.x_min, BOUNDS.x_max)
    player.global_position.y = clampf(player.global_position.y, BOUNDS.y_min, BOUNDS.y_max)

    var done_lines: Array = []
    for sl in _speed_lines:
        var n: Polygon2D = sl["n"]
        n.position.y += float(sl["s"]) * delta
        if n.position.y > 820.0:
            done_lines.append(sl)
    for sl in done_lines:
        _speed_lines.erase(sl)
        sl["n"].queue_free()

    if player.global_position.y <= GOAL_Y:
        _finish()
        return

    spawn_timer -= delta
    if spawn_timer <= 0.0 and geese.size() < 9:
        _spawn_goose()
        spawn_timer = maxf(0.55, 1.0 - float(geese.size()) * 0.05)

    # Hit-stop window freezes the action (but not the decay).
    if _hitstop > 0.0:
        _hitstop -= delta
        if _hitstop <= 0.0:
            Engine.time_scale = 1.0
        return

    var remove: Array = []
    for g in geese:
        var n: Node2D = g["node"]
        var sway: float = g["sway"]
        n.position += Vector2(sin((_time + sway) * 1.9) * 30.0 * delta, 155.0 * delta)
        n.rotation = sin((_time + sway) * 2.3) * 0.08
        if n.position.distance_to(player.global_position) < 34.0:
            _on_goose_hit(n)
            remove.append(g)
        elif n.position.y > 780.0:
            remove.append(g)
    for g in remove:
        geese.erase(g)
        g["node"].queue_free()

func _spawn_goose() -> void:
    var goose := Node2D.new()
    goose.position = Vector2(randf_range(BOUNDS.x_min + 20, BOUNDS.x_max - 20), -20)
    add_child(goose)

    # Visuals live on an inner node so the walk bob doesn't fight the drop.
    var art := Node2D.new()
    goose.add_child(art)
    var body := Props.poly(Props.ellipse(16, 14, 18), Color("#f4f4f4"), Vector2.ZERO)
    art.add_child(body)
    var wing := Props.poly(Props.ellipse(6, 4, 10), Palette.FOG, Vector2(0, -2))
    art.add_child(wing)
    var beak := Props.poly(Props.rounded_rect(12, 4, 2, 3), Palette.BRIGHT, Vector2(-4, 0))
    beak.rotation = deg_to_rad(-30)
    art.add_child(beak)
    var eye := Props.poly(Props.ellipse(2, 2, 8), Palette.INK, Vector2(4, -4))
    art.add_child(eye)
    var leg_col := Color("#f0a020")
    var leg_l := Props.poly(Props.bar(2, 5), leg_col, Vector2(-4, 12))
    art.add_child(leg_l)
    var leg_r := Props.poly(Props.bar(2, 5), leg_col, Vector2(4, 12))
    art.add_child(leg_r)

    var bob := art.create_tween().set_loops()
    bob.tween_property(art, "position:y", -3.0, 0.35).set_trans(Tween.TRANS_SINE)
    bob.tween_property(art, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)

    geese.append({"node": goose, "sway": randf_range(-1.0, 1.0)})

func _spawn_speed_line() -> void:
    var line := Polygon2D.new()
    var x := randf_range(60.0, 1220.0)
    line.polygon = PackedVector2Array([
        Vector2(x, 0), Vector2(x + 6, 0), Vector2(x + 6, 60 + randf_range(0, 90)), Vector2(x, 60 + randf_range(0, 90))])
    line.color = Color(1, 1, 1, randf_range(0.05, 0.12))
    add_child(line)
    line.position.y = -90.0
    _speed_lines.append({"n": line, "s": randf_range(400.0, 700.0)})
    if _speed_lines.size() > 10:
        var last: Dictionary = _speed_lines.pop_front()
        if is_instance_valid(last["n"]):
            last["n"].queue_free()

func _on_goose_hit(n: Node2D) -> void:
    hits += 1
    player.global_position.y += 90.0
    Fx.shake(player.get_node_or_null("Camera2D") as Camera2D, 7.0, 0.3)
    UiKit.flash(self, Palette.RED, 0.28)
    UiKit.burst(self, n.global_position, Palette.PAPER, 12)
    AudioFx.sfx("wrong")
    _hitstop = 0.12
    Engine.time_scale = 0.12
    _update_hits_lbl()

func _update_hits_lbl() -> void:
    hits_lbl.text = "Geese bumped: %d  (each bump = +Stress)" % hits

func _finish() -> void:
    _done = true
    Engine.time_scale = 1.0
    set_process(false)
    for g in geese:
        g["node"].queue_free()
    UiKit.flash(self, Palette.PAPER, 0.5)
    UiKit.burst(self, Vector2(640, GOAL_Y), Palette.GOLD, 30)
    AudioFx.sfx("confirm")
    var next: String = GameState.finish_event({"hits": hits})
    await get_tree().create_timer(1.0).timeout
    UiKit.fade_and_switch(self, next)