extends Node2D
## RUSH TO CLASS: dodge minigame.
## Run up the quad to the Lecture Hall door while avoiding the campus geese.
## Geese = white squares with orange beaks (peaceful, just territorial).
## Hits add Stress; getting there at all adds an on-time GPA bonus.

const GOAL_Y := 80.0
const BOUNDS := {"x_min": 180.0, "x_max": 1100.0, "y_min": 40.0, "y_max": 600.0}
const GEESE_COLOR := Color("#f4f4f4")
const BEAK_COLOR := Color("#f27d0f")

var player: CharacterBody2D
var hits := 0
var spawn_timer := 0.6
var geese: Array = []          # [{node: Polygon2D, sway: float}]
var hits_lbl: Label
var _time := 0.0

const BG := Color("#0A2240")
const GOLD := Color("#e4a024")

func _ready() -> void:
    # Build the world.
    var bg := Polygon2D.new()
    bg.polygon = PackedVector2Array([
        Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
    bg.color = BG
    add_child(bg)

    var path := Polygon2D.new()
    path.polygon = PackedVector2Array([
        Vector2(140, 0), Vector2(1140, 0), Vector2(1100, 720), Vector2(180, 720)])
    path.color = Color("#123a6b")
    add_child(path)

    # The Lecture Hall door (gold - the goal).
    var door := Polygon2D.new()
    door.polygon = PackedVector2Array([
        Vector2(-80, -30), Vector2(80, -30), Vector2(80, 30), Vector2(-80, 30)])
    door.position = Vector2(640, GOAL_Y)
    door.color = GOLD
    add_child(door)
    var door_lbl := Label.new()
    door_lbl.text = "LECTURE HALL"
    door_lbl.position = Vector2(540, 30)
    door_lbl.size = Vector2(200, 30)
    door_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    door_lbl.add_theme_color_override("font_color", GOLD)
    add_child(door_lbl)

    # Player (reuses the campus player scene - bright blue round student).
    var packed := load("res://scenes/player.tscn") as PackedScene
    player = packed.instantiate() as CharacterBody2D
    player.speed = 320.0
    player.global_position = Vector2(640, 600)
    add_child(player)
    var cam := player.get_node_or_null("Camera2D") as Camera2D
    if cam != null:
        cam.enabled = false

    # HUD
    var ui := CanvasLayer.new()
    add_child(ui)
    var top := Label.new()
    top.text = "THE BELL IS RINGING! Dodge the geese, reach the door!"
    top.position = Vector2(0, 20)
    top.size = Vector2(1280, 40)
    top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    top.add_theme_font_size_override("font_size", 24)
    top.add_theme_color_override("font_color", GOLD)
    ui.add_child(top)

    hits_lbl = Label.new()
    hits_lbl.position = Vector2(0, 60)
    hits_lbl.size = Vector2(1280, 30)
    hits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hits_lbl.add_theme_font_size_override("font_size", 16)
    hits_lbl.add_theme_color_override("font_color", Color("#f0f5ff"))
    ui.add_child(hits_lbl)
    _update_hits_lbl()

func _process(delta: float) -> void:
    _time += delta
    # Clamp the player inside the corridor.
    player.global_position.x = clampf(player.global_position.x, BOUNDS.x_min, BOUNDS.x_max)
    player.global_position.y = clampf(player.global_position.y, BOUNDS.y_min, BOUNDS.y_max)

    # Reached the door?
    if player.global_position.y <= GOAL_Y:
        _finish()
        return

    # Spawn geese at a steady, slightly escalating rate.
    spawn_timer -= delta
    if spawn_timer <= 0.0 and geese.size() < 9:
        var goose := Polygon2D.new()
        goose.polygon = PackedVector2Array([
            Vector2(-14, -10), Vector2(14, -10), Vector2(14, 10), Vector2(-14, 10)])
        goose.color = GEESE_COLOR
        goose.position = Vector2(randf_range(BOUNDS.x_min + 20, BOUNDS.x_max - 20), -20)
        add_child(goose)
        var beak := Polygon2D.new()
        beak.polygon = PackedVector2Array([
            Vector2(0, -17), Vector2(8, -8), Vector2(-8, -8)])
        beak.color = BEAK_COLOR
        beak.position = Vector2(0, -2)
        goose.add_child(beak)
        geese.append({"node": goose, "sway": randf_range(-1.0, 1.0)})
        spawn_timer = maxf(0.55, 1.0 - float(geese.size()) * 0.05)

    # Move geese down (with a gentle sway) and check collisions.
    var remove: Array = []
    for g in geese:
        var n: Polygon2D = g["node"]
        var sway: float = g["sway"]
        n.position += Vector2(sin((_time + sway) * 1.8) * 28.0 * delta, 150.0 * delta)
        if n.position.distance_to(player.global_position) < 34.0:
            hits += 1
            player.global_position.y += 90.0
            remove.append(g)
            _update_hits_lbl()
        elif n.position.y > 760.0:
            remove.append(g)
    for g in remove:
        geese.erase(g)
        g["node"].queue_free()

func _update_hits_lbl() -> void:
    hits_lbl.text = "Geese bumped: %d  (each bump = +Stress)" % hits

func _finish() -> void:
    set_process(false)
    var next: String = GameState.finish_event({"hits": hits})
    await get_tree().create_timer(1.0).timeout
    get_tree().change_scene_to_file(next)