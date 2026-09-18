extends Node
## Headless flow test: verifies GameState hands back the right next-scene paths
## at each stage (quiz -> campus -> win/win-conditions).
## Run with: godot --headless res://tests/flow_test.tscn --quit-after 10

var failures := 0

func _ready() -> void:
    _check("fresh run goes to good places", _fresh_run())
    _check("quiz route + reward", _quiz_route())
    _check("win path after exam at 55+", _win_path())
    _check("exam fail path", _fail_path())
    if failures == 0:
        print("FLOW TEST: PASS")
    else:
        print("FLOW TEST: %d FAILURES" % failures)
    get_tree().quit()

func _check(name: String, ok: bool) -> void:
    if not ok:
        failures += 1
        printerr("FAILED: " + name)

func _fresh_run() -> bool:
    GameState.start_run("Computer Science")
    # Day 1 morning lecture should be a plain lecture (no event on day 1).
    var mini: String = GameState.perform_option("lecture", "lecture")
    return mini == "" and GameState.slots_used == 1

func _quiz_route() -> bool:
    GameState.start_run("Computer Science")
    # Rush the day-2 morning lecture -> pop quiz.
    # First consume day 1 fully without triggering anything special.
    GameState.perform_option("cafeteria", "eat")
    GameState.perform_option("flat", "nap")
    GameState.perform_option("cafeteria", "eat")
    if GameState.day != 2:
        return false
    var mini: String = GameState.perform_option("lecture", "lecture")
    if mini != "res://scenes/quiz.tscn":
        return false
    var gpa_before: float = GameState.gpa
    var next: String = GameState.finish_event({"correct": 3, "total": 3})
    return next == "res://scenes/campus.tscn" \
        and absf(GameState.gpa - (gpa_before + 6.0)) < 0.01 \
        and GameState.slots_used == 1

func _win_path() -> bool:
    GameState.start_run("Computer Science")
    # Fast-forward: set up day 7 with a passing GPA.
    GameState.day = 7
    GameState.slots_used = 0
    GameState.gpa = 70.0
    var mini: String = GameState.perform_option("exam", "exam")
    if mini != "res://scenes/quiz.tscn":
        return false
    var next: String = GameState.finish_event({"correct": 4, "total": 5})
    return next == "res://scenes/win.tscn" and GameState.exam_taken

func _fail_path() -> bool:
    GameState.start_run("Computer Science")
    GameState.day = 7
    GameState.gpa = 45.0
    var mini: String = GameState.perform_option("exam", "exam")
    var next: String = GameState.finish_event({"correct": 0, "total": 5})
    return mini == "res://scenes/quiz.tscn" \
        and GameState.lost_reason != "" \
        and next == "res://scenes/lose.tscn"