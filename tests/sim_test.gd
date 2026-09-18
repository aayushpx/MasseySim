extends Node
## Headless balance sim: plays full scripted runs against GameState and prints
## the outcome so we can check the game is beatable but not trivially so.
## Run with: godot --headless res://tests/sim_test.tscn --quit-after 10

# Canned "good player" results for each minigame when it triggers.
const EVENT_RESULTS := {
    "res://scenes/quiz.tscn": {"correct": 3},
    "res://scenes/essay_sprint.tscn": {"greens": 5},
    "res://scenes/rush_to_class.tscn": {"hits": 1},
}

var outcome_log := ""

func _ready() -> void:
    # 1) A careful student for each degree: should graduate.
    for degree in GameState.DEGREES:
        _play(degree, _good_plan(degree), "good")

    # 2) A decent, slightly distracted player: should squeak across the line.
    _play("Computer Science", _decent_plan(), "decent")

    # 3) A sloppy first-try player: attention is a vibe, not a strategy.
    _play("Computer Science", _sloppy_plan(), "sloppy")

    # 4) A lazy student: skips lectures, napping all day. Should drop out.
    _play("Computer Science", _lazy_plan(), "lazy")

    # 5) An over-studier: only library, never eats/naps. Should burn out.
    _play("Computer Science", _burnout_plan(), "burnout")

    print("\n===== SIMULATION RESULTS =====")
    print(outcome_log.strip_edges())
    print("==============================")
    get_tree().quit()

## Run one full plan: each day is 3 actions. Prints one verdict line.
func _play(degree_name: String, plan: Array, label: String) -> void:
    GameState.start_run(degree_name)
    for day_plan in plan:
        for act in day_plan:
            if GameState.lost_reason != "":
                break
            var day_before: int = GameState.day
            var slot_before: int = GameState.slots_used
            var mini: String = GameState.perform_option(act[0], act[1])
            if mini != "":
                var override: Dictionary = act[2] if act.size() > 2 else {}
                var res: Dictionary = override.duplicate()
                if res.is_empty():
                    res = EVENT_RESULTS[mini]
                GameState.finish_event(res)
            if TRACE:
                print("  [%s] d%-2d slot%-2d %s/%s mini=%-44s E%.0f S%.0f G%.0f lost='%s'" % [
                    label, day_before, slot_before, act[0], act[1],
                    mini if mini != "" else "-",
                    GameState.energy, GameState.stress, GameState.gpa,
                    GameState.lost_reason.left(0)])
        if GameState.lost_reason != "":
            break
    var verdict := "WON"
    if GameState.lost_reason != "":
        verdict = "LOST (%s)" % GameState.lost_reason.substr(0, 40)
    outcome_log += "%-14s %-8s | Day %d | E=%3.0f S=%3.0f G=%3.0f\n" % [
        label + "/" + degree_name, verdict,
        GameState.day, GameState.energy, GameState.stress, GameState.gpa]

const TRACE := false

func _good_plan(degree_name: String) -> Array:
    # 7 days x 3 actions of [zone, option].
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

# A mid-skill CS student: good streaks, real mistakes. Should pass, tensely.
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

# Sloppy first-run player: attends sometimes, never studies, bombs the minigames.
# NOTE: no evening (slot 2) lectures - the game rightly refuses those.
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