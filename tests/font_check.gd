extends SceneTree

func _initialize() -> void:
    var ok := true
    for path in ["res://assets/fonts/Fraunces.ttf", "res://assets/fonts/WorkSans.ttf"]:
        var f := FontFile.new()
        var err := f.load_dynamic_font(path)
        print(path, " err=", err)
        if err != OK:
            ok = false
    quit(0 if ok else 1)
