class_name Fx
## Cheap, dependency-free screen-feel helpers. Used by scenes that own a
## Camera2D to add a short impact shake without any extra nodes.

static func shake(cam: Camera2D, amp: float = 6.0, dur: float = 0.3) -> void:
    if cam == null:
        return
    var steps := 7
    var tw := cam.create_tween()
    for i in steps:
        var a: float = amp * (1.0 - float(i) / float(steps))
        tw.tween_property(cam, "offset", Vector2(randf_range(-a, a), randf_range(-a, a)), dur / float(steps))
    tw.tween_property(cam, "offset", Vector2.ZERO, 0.06)