extends Node
## Active-run campus smoke test: instantiates the campus, starts a run, drives
## real actions (including a day advance, an event and a minigame hand-off) so
## the HUD refresh, meter tweens, day wipe and particle paths all execute.
## Run: godot --headless res://tests/campus_smoke.tscn --quit-after 30

func _ready() -> void:
    GameState.start_run("Computer Science")
    var campus: Node = load("res://scenes/campus.tscn").instantiate()
    add_child(campus)
    await get_tree().process_frame
    await get_tree().process_frame

    # Day 1, plain actions -> triggers a day advance on the third.
    GameState.perform_option("cafeteria", "eat")
    GameState.perform_option("flat", "nap")
    GameState.perform_option("cafeteria", "eat")
    await get_tree().process_frame

    # Day 2 morning lecture -> pop quiz, then hand back a result.
    var mini: String = GameState.perform_option("lecture", "lecture")
    var next: String = GameState.finish_event({"correct": 2, "total": 3})
    await get_tree().process_frame
    await get_tree().process_frame

    # Exercise the popup build path too.
    campus.call("_open_popup", "library")
    await get_tree().process_frame

    var ok: bool = GameState.day == 2 \
        and mini == "res://scenes/quiz.tscn" \
        and next == "res://scenes/campus.tscn"
    print("CAMPUS SMOKE: ", "OK" if ok else "FAIL",
        " day=", GameState.day, " gpa=%.0f" % GameState.gpa)
    get_tree().quit(0 if ok else 1)