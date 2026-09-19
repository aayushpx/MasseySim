extends Node
func _ready() -> void:
    GameState.start_run("Computer Science")
    const label := "v4"
    var campus: Node = load("res://scenes/campus.tscn").instantiate()
    add_child(campus)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var p: CharacterBody2D = campus.get_node("Player")
    var rig: Node2D = p.get_node("Rig")
    print("%s start pos=%s rig.scale.x=%s" % [label, p.position, rig.scale.x])

    var d := InputEventKey.new()
    d.physical_keycode = KEY_D
    d.pressed = true
    Input.parse_input_event(d)
    for i in 40:
        await get_tree().physics_frame
        if i == 10 or i == 39:
            print("%s mid pos=%s rig.scale.x=%s" % [label, p.position, rig.scale.x])
    var du := InputEventKey.new()
    du.physical_keycode = KEY_D
    du.pressed = false
    Input.parse_input_event(du)

    var w := InputEventKey.new()
    w.physical_keycode = KEY_W
    w.pressed = true
    Input.parse_input_event(w)
    for i in 40:
        await get_tree().physics_frame
        if i == 10 or i == 39:
            print("%s up pos=%s rig.scale.x=%s" % [label, p.position, rig.scale.x])
    var wu := InputEventKey.new()
    wu.physical_keycode = KEY_W
    wu.pressed = false
    Input.parse_input_event(wu)
    print("%s end" % label)
    get_tree().quit()
