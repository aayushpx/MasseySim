extends CharacterBody2D
## The player: a bright-blue round "student". WASD/arrows to move.
## Built entirely in code - no external art needed (placeholder look).

@export_range(0.0, 800.0) var speed := 240.0
const HALF := 14.0          # body radius (visual)

@onready var body: Polygon2D

func _ready() -> void:
    # Visual: bright blue circle with a smaller darker-brim "cap" square.
    body = Polygon2D.new()
    body.polygon = Shapes.circle(0.0, 0.0, HALF)
    body.color = Color("#25AAE1")
    add_child(body)

    var cap := Polygon2D.new()
    cap.polygon = PackedVector2Array([
        Vector2(-9, -9), Vector2(9, -9), Vector2(9, 9), Vector2(-9, 9)])
    cap.position = Vector2(0, -6)
    cap.color = Color("#0A2240")
    add_child(cap)

    # Collision: a circle so zones/geese can bump us sensibly.
    var shape := CollisionShape2D.new()
    var circ := CircleShape2D.new()
    circ.radius = HALF
    shape.shape = circ
    add_child(shape)

    # Camera follows the player around the campus.
    var cam := Camera2D.new()
    cam.position_smoothing_enabled = true
    cam.position_smoothing_speed = 6.0
    add_child(cam)

func _physics_process(_delta: float) -> void:
    var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = dir * speed
    move_and_slide()