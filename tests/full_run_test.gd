extends Node
## Scripted full-game run mounting the REAL campus scene and driving every
## action through the real popup/choose path, then handing back event results.
##
## Actions that never trigger a scene switch (eat/nap/study/chill/quiznight)
## go through campus._open_popup + _choose_option, exercising the live popup
## build, option labels, pause/unpause, and HUD/meter refresh + day wipe for a
## whole 7-day game. Event-capable options (lecture/assignment/exam) go through
## GameState.perform_option + finish_event — campus's event branch only routes
## the non-empty result to _fade_out_then (a scene switch; covered by
## campus_smoke). Terminals: every degree good run should win; distracted,
## sloppy, lazy and burnout runs should lose.
## Run: godot --headless res://tests/full_run_test.tscn --quit-after 40

const EVENT_RESULTS := {
    "res://scenes/quiz.tscn": {"correct": 3, "total": 3},
    "res://scenes/essay_sprint.tscn": {"greens": 5},
    "res://scenes/rush_to_class.tscn": {"hits": 1},
}
const PLAIN_OPTIONS := ["eat", "nap", "study", "chill"]

var failures := 0
const TRACE := false


func _ready() -> void:
    GameState.start_run("Computer Science")
    var campus: Node = load("res://scenes/campus.tscn").instantiate()
    add_child(campus)
    await get_tree().process_frame
    await get_tree().process_frame

    for degree: String in GameState.DEGREES:
        await _play(campus, degree, _good_plan(degree), "good", true)
    await _play(campus, "Computer Science", _decent_plan(), "decent", true)
    await _play(campus, "Computer Science", _sloppy_plan(), "sloppy", false)
    await _play(campus, "Computer Science", _lazy_plan(), "lazy", false)
    await _play(campus, "Computer Science", _burnout_plan(), "burnout", false)

    print("FULL RUN TEST: ", "PASS" if failures == 0 else "%d FAILURE(S)" % [failures])
    await get_tree().process_frame
    await get_tree().process_frame
    get_tree().quit(0 if failures == 0 else 1)


## Play one full run using the live campus; returns nothing, bumps failures.
func _play(campus: Node, degree: String, plan: Array, label: String, expect_win: bool) -> void:
    GameState.start_run(degree)
    await get_tree().process_frame
    campus._refresh_hud()

    for day_plan in plan:
        if GameState.lost_reason != "":
            break
        for act: Array in day_plan:
            if GameState.lost_reason != "":
                break
            var zone: String = act[0]
            var opt: String = act[1]
            _act(campus, zone, opt, act, label)

    if expect_win and GameState.lost_reason != "":
        _fail("%s/%s: expected win but LOST (%s)" % [label, degree, GameState.lost_reason.left(50)])
    elif not expect_win and GameState.lost_reason == "":
        _fail("%s: expected a loss but the run continued (day=%d)" % [label, GameState.day])
    elif expect_win:
        var won: bool = GameState.exam_taken and GameState.lost_reason == ""
        if not won:
            _fail("%s/%s: finished without sitting finals" % [label, degree])
        else:
            print("  %-7s %-18s WON  day=%d E=%.0f S=%.0f G=%.0f" % [
                label, degree, GameState.day, GameState.energy, GameState.stress, GameState.gpa])
    else:
        print("  %-7s %-18s LOST day=%d (%s)" % [
            label, degree, GameState.day, GameState.lost_reason.left(50)])


## Perform one action: plain options through live campus UI, events via GameState.
func _act(campus: Node, zone: String, opt: String, act: Array, label: String) -> void:
    var offered: Array = GameState.zone_options(zone).map(func(o: Dictionary) -> String: return o.get("id", ""))
    if not offered.has(opt):
        _fail("%s: %s/%s not offered (have %s)" % [label, zone, opt, offered])
    if opt in PLAIN_OPTIONS:
        campus._open_popup(zone)
        campus._choose_option(zone, opt)
        _trace(zone, opt, "")
        return
    var mini: String = GameState.perform_option(zone, opt)
    if mini == "":
        _trace(zone, opt, "no-minigame")
        return
    var res: Dictionary = {}
    if act.size() > 2:
        res = (act[2] as Dictionary).duplicate()
    if res.is_empty():
        if not EVENT_RESULTS.has(mini):
            _fail("%s: unknown minigame %s" % [label, mini])
            return
        res = EVENT_RESULTS[mini]
    GameState.finish_event(res)
    _trace(zone, opt, mini)

func _trace(zone: String, opt: String, mini: String) -> void:
    if not TRACE:
        return
    print("  TRACE [%s] d%d slot%d %s/%s mini=%s E=%.0f S=%.0f G=%.0f exam=%s lost=%s" % [
        GameState.degree, GameState.day, GameState.slots_used, zone, opt,
        mini if mini != "" else "-",
        GameState.energy, GameState.stress, GameState.gpa,
        GameState.exam_taken, "yes" if GameState.lost_reason != "" else "no"])


func _fail(msg: String) -> void:
    failures += 1
    printerr("FAILED: " + msg)


# --- Plans (shared with sim_test) ------------------------------------------

func _good_plan(degree_name: String) -> Array:
    match degree_name:
        "Computer Science":
            return [
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["lecture", "lecture"]],
                [["lecture", "lecture"], ["library", "study"], ["cafeteria", "eat"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["clubroom", "quiznight"]],
                [["exam", "exam"], ["cafeteria", "eat"], ["library", "study"]],
            ]
        "Software Engineering":
            return [
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["library", "assignment"], ["cafeteria", "eat"]],
                [["lecture", "lecture"], ["library", "study"], ["cafeteria", "eat"]],
                [["lecture", "lecture"], ["lecture", "lecture"], ["library", "assignment"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["clubroom", "quiznight"]],
                [["exam", "exam"], ["cafeteria", "eat"], ["library", "study"]],
            ]
        "Veterinary Science":
            return [
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["library", "assignment"], ["cafeteria", "eat"]],
                [["lecture", "lecture"], ["lecture", "lecture"], ["cafeteria", "eat"]],
                [["lecture", "lecture"], ["library", "assignment"], ["cafeteria", "eat"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["clubroom", "quiznight"]],
                [["exam", "exam"], ["cafeteria", "eat"], ["library", "study"]],
            ]
        _:  # Food Science
            return [
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
                [["lecture", "lecture"], ["library", "assignment"], ["cafeteria", "eat"]],
                [["lecture", "lecture"], ["library", "study"], ["cafeteria", "eat"]],
                [["lecture", "lecture"], ["library", "assignment"], ["lecture", "lecture"]],
                [["lecture", "lecture"], ["cafeteria", "eat"], ["clubroom", "quiznight"]],
                [["exam", "exam"], ["cafeteria", "eat"], ["library", "study"]],
            ]

func _decent_plan() -> Array:
    return [
        [["lecture", "lecture"], ["cafeteria", "eat"], ["library", "study"]],
        [["lecture", "lecture", {"correct": 1}], ["cafeteria", "eat"], ["flat", "nap"]],
        [["flat", "nap"], ["lecture", "lecture", {"hits": 3}], ["library", "assignment", {"greens": 2}]],
        [["cafeteria", "eat"], ["library", "study"], ["cafeteria", "eat"]],
        [["lecture", "lecture"], ["cafeteria", "eat"], ["flat", "nap"]],
        [["lecture", "lecture"], ["cafeteria", "eat"], ["flat", "nap"]],
        [["exam", "exam", {"correct": 2}], ["cafeteria", "eat"], ["library", "study"]],
    ]

func _sloppy_plan() -> Array:
    return [
        [["lecture", "lecture"], ["flat", "nap"], ["cafeteria", "eat"]],
        [["lecture", "lecture", {"correct": 0}], ["cafeteria", "eat"], ["flat", "nap"]],
        [["lecture", "lecture", {"hits": 5}], ["library", "assignment", {"greens": 1}], ["cafeteria", "eat"]],
        [["cafeteria", "eat"], ["flat", "nap"], ["cafeteria", "eat"]],
        [["lecture", "lecture"], ["cafeteria", "eat"], ["flat", "nap"]],
        [["cafeteria", "eat"], ["flat", "nap"], ["cafeteria", "eat"]],
        [["exam", "exam", {"correct": 1}], ["cafeteria", "eat"], ["flat", "nap"]],
    ]

func _lazy_plan() -> Array:
    var plan: Array = []
    for _i in range(7):
        plan.append([["cafeteria", "eat"], ["flat", "nap"], ["flat", "nap"]])
    return plan

func _burnout_plan() -> Array:
    var plan: Array = []
    for _i in range(7):
        plan.append([["library", "study"], ["library", "study"], ["library", "study"]])
    return plan