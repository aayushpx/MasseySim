extends CharacterBody2D
## The student. A small geometric person (rounded shapes, Massey-blue hoodie)
## built entirely from Polygon2D pieces with a proper AnimationPlayer walk
## cycle: bob + arm/leg swing, head follow, rear-panel flip when walking away.
## Degree selection swaps a small accessory so the four majors read at a glance.

@export_range(0.0, 800.0) var speed := 240.0
const ACCEL := 2600.0
const SPRINT_MULT := 1.6

const BODY_RX := 12.0
const BODY_RY := 10.0
const HEAD_R := 8.0

var rig: Node2D
var rear_panel: Polygon2D
var anim: AnimationPlayer
var sprint_dust: CPUParticles2D
var acc: Node2D
var cam_node: Camera2D

## Soft dark blob under the player: grounds the character in the scene and
## doubles as a cheap standing depth cue. Sits below the whole rig.
func _build_shadow() -> void:
	var sh := Props.poly(Props.ellipse(13.0, 5.5, 16), Color(0.0, 0.0, 0.0, 0.28), Vector2(3, 9), -1)
	sh.name = "Shadow"
	add_child(sh)

func _ready() -> void:
	_build_rig()
	_build_shadow()
	_build_animation()
	_build_accessory()

	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 8.0
	shape.shape = circ
	add_child(shape)

	var cam := Camera2D.new()
	cam.name = "PlayerCam"          # auto-rename breaks get_node("Camera2D")
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	cam_node = cam
	add_child(cam)
	_register_sprint()
	_build_sprint_dust()

func _build_rig() -> void:
	rig = Node2D.new()
	rig.name = "Rig"
	rig.position = Vector2.ZERO
	add_child(rig)

	# Legs (dark trousers, pivot at hip).
	var leg_l := _limb("LegL", 5.0, 8.0, Palette.INK)
	leg_l.position = Vector2(-6, 4)
	rig.add_child(leg_l)
	var leg_r := _limb("LegR", 5.0, 8.0, Palette.INK)
	leg_r.position = Vector2(6, 4)
	rig.add_child(leg_r)

	# Body: Massey-blue hoodie blob.
	var body := Props.poly(Props.ellipse(BODY_RX, BODY_RY, 22), Palette.BLUE, Vector2(0, -3), 2)
	body.name = "Body"
	rig.add_child(body)

	# Hood sheen: a flat lighter segment to keep the blob from reading as a pill.
	var sheen := Props.poly(Props.rounded_rect(14.0, 9.0, 6.0, 4), Palette.LIGHT, Vector2(0, -4), 3)
	sheen.modulate.a = 0.45
	rig.add_child(sheen)

	# Rear panel: darker hood shown when the student walks away from camera.
	rear_panel = Props.poly(Props.ellipse(BODY_RX + 1.0, BODY_RY + 1.0, 22), Palette.INK, Vector2(0, -3), 1)
	rear_panel.visible = false
	rig.add_child(rear_panel)

	# Arms (sleeve pivot at shoulder, hand blob at the far end).
	var arm_l := _limb("ArmL", 6.0, 10.0, Palette.BLUE)
	arm_l.position = Vector2(-11, -4)
	rig.add_child(arm_l)
	var hand_l := _hand("HandL", 3.0)
	hand_l.position = Vector2(0, 6)
	arm_l.add_child(hand_l)
	var arm_r := _limb("ArmR", 6.0, 10.0, Palette.BLUE)
	arm_r.position = Vector2(11, -4)
	rig.add_child(arm_r)
	var hand_r := _hand("HandR", 3.0)
	hand_r.position = Vector2(0, 6)
	arm_r.add_child(hand_r)

	# Head: skin + hair cap.
	var head := Props.poly(Props.ellipse(HEAD_R, HEAD_R, 18), Palette.SKIN, Vector2(0, -14), 4)
	head.name = "Head"
	rig.add_child(head)
	var hair := Props.poly(Props.rounded_rect(HEAD_R * 1.9 + 2.0, HEAD_R * 1.5, HEAD_R, 8), Palette.HAIR, Vector2(0, -17), 5)
	rig.add_child(hair)

func _limb(node_name: String, w: float, len: float, col: Color) -> Polygon2D:
	var p := Props.rounded_rect(w, len, w * 0.5, 3)
	for i in p.size():
		p[i] += Vector2(0, len * 0.5)   # shift so origin is the top pivot
	var n := Props.poly(p, col, Vector2.ZERO, 2)
	n.name = node_name
	return n

func _hand(node_name: String, r: float) -> Polygon2D:
	var n := Props.poly(Props.ellipse(r, r, 12), Palette.SKIN, Vector2.ZERO, 3)
	n.name = node_name
	return n

## Degree-based flavour accessory (top-down, so a "front" item reads like a
## vest or side pouch when walking around).
func _build_accessory() -> void:
	acc = Node2D.new()
	acc.name = "Accessory"
	acc.position = Vector2(0, -3)
	acc.z_index = 6
	rig.add_child(acc)
	match GameState.degree:
		"Computer Science":
			var bag := Props.poly(Props.rounded_rect(6.0, 8.0, 2.0, 2), Palette.INK, Vector2(10, 2), 0)
			acc.add_child(bag)
			var strap := Props.poly(Props.bar(2.0, 9.0), Palette.GOLD, Vector2(12, -3), 0)
			acc.add_child(strap)
		"Software Engineering":
			var board := Props.poly(Props.rounded_rect(5.0, 7.0, 1.5, 2), Palette.PAPER, Vector2(11, 1), 0)
			acc.add_child(board)
			var pin := Props.poly(Props.bar(4.0, 1.5), Palette.GOLD, Vector2(11, 1), 0)
			acc.add_child(pin)
		"Veterinary Science":
			var bell := Props.poly(Props.ellipse(2.5, 2.5, 12), Palette.GOLD, Vector2(0, 3), 0)
			acc.add_child(bell)
			var cord := Props.poly(Props.bar(1.5, 9.0), Palette.GOLD, Vector2(0, -2), 0)
			acc.add_child(cord)
		"Food Science":
			var apron := Props.poly(Props.rounded_rect(9.0, 11.0, 3.0, 3), Palette.BRIGHT, Vector2(0, 1), 0)
			apron.modulate.a = 0.85
			acc.add_child(apron)
			var trim := Props.poly(Props.bar(10.0, 2.0), Palette.GOLD, Vector2(0, -5), 0)
			acc.add_child(trim)

func _build_animation() -> void:
	anim = AnimationPlayer.new()
	anim.name = "Anim"
	add_child(anim)

	# --- walk: bob + opposite-phase arm/leg swing ---
	var walk := Animation.new()
	walk.length = 0.55
	walk.loop_mode = Animation.LOOP_LINEAR
	_track_curve(walk, "Rig:position:y", 0.55, [0.0, 0.0, 0.275, -3.5, 0.55, 0.0])
	_track_curve(walk, "Rig/ArmL:rotation:z", 0.55, [0.0, 0.75, 0.275, -0.7, 0.55, 0.75])
	_track_curve(walk, "Rig/ArmR:rotation:z", 0.55, [0.0, -0.75, 0.275, 0.7, 0.55, -0.75])
	_track_curve(walk, "Rig/LegL:rotation:z", 0.55, [0.0, -0.55, 0.275, 0.55, 0.55, -0.55])
	_track_curve(walk, "Rig/LegR:rotation:z", 0.55, [0.0, 0.55, 0.275, -0.55, 0.55, 0.55])

	# --- idle: tiny breathing bob ---
	var idle := Animation.new()
	idle.length = 0.6
	idle.loop_mode = Animation.LOOP_LINEAR
	_track_curve(idle, "Rig:position:y", 0.6, [0.0, 0.0, 0.3, -1.2, 0.6, 0.0])
	_track_curve(idle, "Rig/ArmL:rotation:z", 0.6, [0.0, 0.15, 0.3, 0.08, 0.6, 0.15])
	_track_curve(idle, "Rig/ArmR:rotation:z", 0.6, [0.0, -0.15, 0.3, -0.08, 0.6, -0.15])
	var lib := AnimationLibrary.new()
	lib.add_animation("walk", walk)
	lib.add_animation("idle", idle)
	anim.add_animation_library("", lib)
	anim.play("idle")

func _track_curve(a: Animation, path: String, _len: float, keys: Array) -> void:
	var idx := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(idx, NodePath(path))
	var i := 0
	while i < keys.size() - 1:
		a.track_insert_key(idx, keys[i], keys[i + 1])
		i += 2

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var sprinting := Input.is_physical_key_pressed(KEY_SHIFT) and dir.length() > 0.01
	var spd := speed * (SPRINT_MULT if sprinting else 1.0)
	if dir.length() > 0.01:
		velocity = velocity.move_toward(dir * spd, ACCEL * delta)
		_update_pose(dir)
		anim.speed_scale = 1.35 if sprinting else 1.0
		sprint_dust.emitting = sprinting
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
		anim.speed_scale = 1.0
		sprint_dust.emitting = false
		if anim.current_animation != "idle":
			anim.play("idle")
	move_and_slide()

func _update_pose(dir: Vector2) -> void:
	var side := absf(dir.x) > absf(dir.y)
	# Node2D has no flip_h (that's Sprite2D) — mirror the whole rig via scale.X.
	rig.scale.x = -1.0 if (side and dir.x < 0.0) else 1.0
	# Walking "up" turns the student's back: swap in the darker hood panel.
	rear_panel.visible = not side and dir.y > 0.0
	rear_panel.z_index = 6 if rear_panel.visible else 1


## Bind a "sprint" action at runtime so project.godot's input map stays untouched.
func _register_sprint() -> void:
	if InputMap.has_action("sprint"):
		return
	var act := InputEventKey.new()
	act.physical_keycode = KEY_SHIFT
	InputMap.add_action("sprint")
	InputMap.action_add_event("sprint", act)

## Gold speed-lines trailing the student on shift-sprint: thin CPUParticles2D
## streaks just above floor level, off when idle/walking, on while sprinting.
func _build_sprint_dust() -> void:
	sprint_dust = CPUParticles2D.new()
	sprint_dust.name = "SprintDust"
	sprint_dust.z_index = 9
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 1.0])
	gr.colors = PackedColorArray([Palette.GOLD, Color(Palette.GOLD, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gr
	tex.width = 8
	tex.height = 2
	sprint_dust.texture = tex
	sprint_dust.amount = 12
	sprint_dust.lifetime = 0.4
	sprint_dust.one_shot = false
	sprint_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sprint_dust.emission_sphere_radius = 4.0
	sprint_dust.direction = Vector2(-1, 0)
	sprint_dust.spread = 14.0
	sprint_dust.gravity = Vector2.ZERO
	sprint_dust.initial_velocity_min = 30.0
	sprint_dust.initial_velocity_max = 70.0
	sprint_dust.damping_min = 1.0
	sprint_dust.damping_max = 2.0
	var dust_scale := Curve.new()
	dust_scale.add_point(Vector2(0.0, 0.0))
	dust_scale.add_point(Vector2(0.4, 1.0))
	dust_scale.add_point(Vector2(1.0, 0.0))
	sprint_dust.scale_amount_curve = dust_scale
	sprint_dust.color_ramp = gr
	sprint_dust.emitting = false
	if rig:
		rig.add_child(sprint_dust)
