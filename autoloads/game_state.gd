extends Node
## Autoload Singleton: GameState
## This lives for the whole game session and holds EVERYTHING about the current
## run: the three meters, the day/slot clock, the chosen degree, the event
## schedule and the rules for what each action does. Minigames read results
## here and hand their rewards back before returning to the campus.

signal meters_changed
signal day_changed

# --- Tunable numbers (Balance Pass 1) -----------------------------------
const ENERGY_MAX := 100.0
const STRESS_MAX := 100.0
const GPA_MAX := 100.0
const GAME_DAYS := 7
const SLOTS_PER_DAY := 3
const PASS_GPA := 55.0      # need this after finals to graduate
const SUSPEND_GPA := 40.0   # GPA below this = academic suspension
const LATE_PENALTY := 10.0
const ASSIGN_DAYS := [3, 5, 6]
const POPQUIZ_DAYS := [2, 4]
const EXAM_DAYS := [3]      # rush-to-class day(s) - first lecture of the day

const DEGREES := {
	"Computer Science": "Debugging gremlins and 2am builds.",
	"Software Engineering": "Stand-ups, sprints and scrum jokes.",
	"Veterinary Science": "Friendly cows, VERY motivated llamas.",
	"Food Science": "Pavlova science. It's not a crime.",
}

# Effects of each base activity (energy / stress / gpa ticks)
const ACTIONS := {
	"lecture":    {"energy": -10, "stress": 8,  "gpa": 5},
	"study":      {"energy": -11, "stress": 9,  "gpa": 8},
	"eat":        {"energy": 16,  "stress": -5, "gpa": 0},
	"nap":        {"energy": 22,  "stress": -3, "gpa": 0},
	"chill":      {"energy": -3,  "stress": -9, "gpa": 0},
	"quiznight":  {"energy": -2,  "stress": -6, "gpa": 3},
}

# --- Run state ----------------------------------------------------------
var degree := "Computer Science"
var energy := 70.0
var stress := 30.0
var gpa := 60.0
var day := 1
var slots_used := 0
var exam_taken := false
var has_run_started := false
var lost_reason := ""
var toast_message := ""
var current_zone := ""        # zone key the player is standing in (set by campus)
var assignments_done := {}
var pop_quiz_used := {}
var rush_used := false
var event_mode := {}          # details handed to the next minigame
var last_result := {}         # keeps "this is why you won/lost" text for screens

func _ready() -> void:
	_setup_input_actions()

func _setup_input_actions() -> void:
	## Register WASD + arrows + E/Space as actions. Done at runtime so the
	## hand-written project.godot stays tiny and error-free.
	var action_map := {
		"move_left":  [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up":    [KEY_W, KEY_UP],
		"move_down":  [KEY_S, KEY_DOWN],
		"interact":   [KEY_E, KEY_SPACE],
	}
	for action in action_map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in action_map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

func start_run(degree_name: String) -> void:
	degree = degree_name
	energy = 70.0
	stress = 30.0
	gpa = 60.0
	day = 1
	slots_used = 0
	exam_taken = false
	has_run_started = true
	lost_reason = ""
	toast_message = "Day 1. You've got this. Probably."
	current_zone = ""
	assignments_done = {3: false, 5: false, 6: false}
	pop_quiz_used = {}
	rush_used = false
	event_mode = {}
	last_result = {}
	emit_signal("meters_changed")
	emit_signal("day_changed")

# --- Day / slot helpers -------------------------------------------------
func slot_name() -> String:
	return ["Morning", "Afternoon", "Evening"][slots_used]

func slots_left() -> int:
	return SLOTS_PER_DAY - slots_used

# --- Meter maths --------------------------------------------------------
func _add(meter: String, amount: float) -> void:
	match meter:
		"energy":
			energy = clampf(energy + amount, 0.0, ENERGY_MAX)
		"stress":
			stress = clampf(stress + amount, 0.0, STRESS_MAX)
		"gpa":
			gpa = clampf(gpa + amount, 0.0, GPA_MAX)
	emit_signal("meters_changed")

func _check_lose() -> void:
	if lost_reason != "":
		return
	if energy <= 0.0:
		lost_reason = "You collapsed from sleep deprivation outside the library. The ducks saw everything."
		last_result = {"kind": "energy"}
	elif stress >= STRESS_MAX:
		lost_reason = "Burnout at 100. The campus geese finally respected your hustle."
		last_result = {"kind": "stress"}
	elif gpa < SUSPEND_GPA:
		lost_reason = "Academic suspension: your GPA slid under %d. The degree broke up with you first." % SUSPEND_GPA
		last_result = {"kind": "gpa"}

# --- Zone action options (shown in the popup when you press E) ----------
func zone_options(zone: String) -> Array:
	var out: Array = []
	match zone:
		"lecture":
			out.append({"id": "lecture", "label": "Attend the lecture (+GPA)"})
		"library":
			out.append({"id": "study", "label": "Study hard at The Spiral (+GPA, +Stress)"})
			if day in ASSIGN_DAYS and not assignments_done.get(day, false):
				out.append({"id": "assignment", "label": "Work on due assignment (!!)"})
		"cafeteria":
			out.append({"id": "eat", "label": "Eat + trauma-bonds (+Energy)"})
		"flat":
			out.append({"id": "nap", "label": "Nap like it owes you money (+Energy)"})
		"clubroom":
			out.append({"id": "chill", "label": "Chill at Club Night (--Stress)"})
			if day == 6 and slots_used == 2:
				out.append({"id": "quiznight", "label": "MUITSA Quiz Night (+GPA, -Stress)"})
		"exam":
			if day == 7 and not exam_taken:
				out.append({"id": "exam", "label": "Sit your FINALS - make it count"})
			elif exam_taken:
				out.append({"id": "exam", "label": "Finals done - you're ghosting uni now"})
			else:
				out.append({"id": "exam", "label": "Locked - Finals start Day 7"})
	return out

# --- Performing a chosen action -----------------------------------------
## Returns a minigame scene path to switch to, or "" to stay on campus.
func perform_option(zone: String, opt_id: String) -> String:
	if not has_run_started:
		return ""
	var ev := {}
	match zone:
		"lecture":
			ev = _lecture_event()
			if ev.is_empty():
				if slots_used == 2:
					toast_message = "No lecture this evening. Lectures run morning/afternoon only."
					return ""
				_apply_and_finish(opt_id)
				return ""
			event_mode = ev
			return _minigame_scene(ev)
		"library":
			if opt_id == "assignment":
				event_mode = {
					"type": "essay", "mode": "assignment", "assign_day": day,
					"title": "Finish the assignment before the Wi-Fi drops",
					"prompt": "Hit SPACE in the green when each paragraph is 'done'",
					"blurb": "The library coffee machine is your co-author now.",
				}
				return _minigame_scene(event_mode)
			_apply_and_finish(opt_id)
			return ""
		"clubroom":
			if opt_id == "quiznight":
				event_mode = {
					"type": "pop_quiz", "category": "muitsa",
					"title": "MUITSA Quiz Night - all degrees welcome",
					"blurb": "Purple and gold, a microwave that has seen things, and a real code of conduct. It's a society.",
				}
				return _minigame_scene(event_mode)
			_apply_and_finish(opt_id)
			return ""
		"exam":
			if day != 7:
				toast_message = "The exam hall is sealed until Finals Week (Day 7)."
				return ""
			if exam_taken:
				return ""
			event_mode = {"type": "exam"}
			return _minigame_scene(event_mode)
		_:
			_apply_and_finish(opt_id)
			return ""
	return ""

## Which special event fires for THIS lecture slot, or {}.
func _lecture_event() -> Dictionary:
	if day == 3 and not rush_used:
		rush_used = true
		return {"type": "rush"}
	var de := _degree_event()
	if not de.is_empty():
		return de
	if day in POPQUIZ_DAYS and not pop_quiz_used.has(day):
		pop_quiz_used[day] = true
		return {"type": "pop_quiz", "category": "general", "title": "Pop quiz! No one mentioned this.", "blurb": "The lecturer really did say 'quiz this week'. Allegedly."}
	return {}

## The single unique event per degree, or {}.
func _degree_event() -> Dictionary:
	match degree:
		"Computer Science":
			if day == 3 and slots_used == 2:
				return {"type": "pop_quiz", "category": "cs",
						"title": "Sunday Night Segfault", "blurb": "The build server is on fire. Pick the fix."}
		"Software Engineering":
			if day == 5 and slots_used == 1:
				return {"type": "essay", "mode": "standup",
						"title": "Sprint Stand-Up Sprint", "prompt": "Answer stand-up questions in the green zone",
						"blurb": "The scrum master is counting down and the sprint board is judging your soul. Speak the sacred words."}
		"Veterinary Science":
			if day == 4 and slots_used == 1:
				return {"type": "pop_quiz", "category": "vet",
						"title": "The Great Llama Upheaval", "blurb": "Lab llama 472 has escaped into the quad. Choose wisely."}
		"Food Science":
			if day == 5 and slots_used == 2:
				return {"type": "essay", "mode": "pavlova",
						"title": "Mystery Pavlova Panel", "prompt": "Name the flavour before the judges judge you",
						"blurb": "Judges: 'the texture is... aspirational.'"}
	return {}

func _minigame_scene(ev: Dictionary) -> String:
	match ev.get("type", ""):
		"luck":
			return ""
		_:
			if ev.get("type") == "rush":
				return "res://scenes/rush_to_class.tscn"
			if ev.get("type") == "pop_quiz" or ev.get("type") == "exam":
				return "res://scenes/quiz.tscn"
			if ev.get("type") == "essay":
				return "res://scenes/essay_sprint.tscn"
	return ""

func _apply_and_finish(opt_id: String) -> void:
	if ACTIONS.has(opt_id):
		var fx: Dictionary = ACTIONS[opt_id]
		_add("energy", fx["energy"])
		_add("stress", fx["stress"])
		_add("gpa", fx["gpa"])
	_after_action()

## One slot is spent. If the day is over, roll into the next day.
func _after_action() -> void:
	slots_used += 1
	_check_lose()
	if lost_reason != "":
		return
	if slots_used >= SLOTS_PER_DAY:
		_advance_day()
	emit_signal("day_changed")

func _advance_day() -> void:
	# IMPORTANT: reset the slot index BEFORE any _add() calls. Each _add()
	# emits meters_changed, which the campus HUD reacts to by calling
	# slot_name() - reading the stale end-of-day index (3) out of bounds.
	slots_used = 0
	# Night auto-sleep: rest up...
	_add("energy", 22.0)
	_add("energy", -13.0)     # overnight drift: even asleep you leak battery
	_add("stress", -4.0)
	_add("stress", 3.0)       # the daily grind hums on
	# ...but you *do* forget lecture content overnight.
	_add("gpa", -3.0)
	# Late assignments bite next morning (only mentioned the once).
	if day in ASSIGN_DAYS and not assignments_done.get(day, false):
		_add("gpa", -LATE_PENALTY)
		toast_message = "Assignment from Day %d was late! GPA -%d" % [day, int(LATE_PENALTY)]
	day += 1
	if day <= GAME_DAYS:
		emit_signal("day_changed")
	elif not exam_taken:
		lost_reason = "Finals Week came and went. You never entered the exam hall. The degree left you before you left it."
		last_result = {"kind": "noshow"}

## A minigame finished; apply its rewards, spend the slot, pick next screen.
## Returns the scene path to switch to.
func finish_event(results: Dictionary) -> String:
	if not has_run_started:
		return "res://scenes/main_menu.tscn"
	var t: String = event_mode.get("type", "")
	match t:
		"pop_quiz":
			var c: int = results.get("correct", 0)
			var total: int = results.get("total", 3)
			_add("gpa", float(c) * 2.0)
			_add("stress", 2.0)
			_add("energy", -4.0)
			if c == total:
				toast_message = "Aced the quiz! GPA +%d. No notes were harmed." % (c * 2)
			else:
				toast_message = "Quiz over: %d/%d correct. GPA +%d" % [c, total, c * 2]
		"exam":
			exam_taken = true
			var c: int = results.get("correct", 0)
			var total: int = results.get("total", 6)
			var bumps: Array[float] = [0.0, 1.0, 3.0, 5.0, 8.0, 11.0, 14.0]
			_add("gpa", bumps[clampi(c, 0, 6)])
			_add("stress", 6.0)
			toast_message = "Finals wrapped: %d/%d correct. The hall exhales." % [c, total]
			if gpa < PASS_GPA:
				lost_reason = "Finals done, but GPA %.0f didn't clear the 55 pass line. A valiant effort, very un-signed papers." % gpa
				last_result = {"kind": "examfail", "gpa": gpa}
		"essay":
			var g: int = results.get("greens", 0)
			if g >= 3:
				_add("gpa", 7.0)
			else:
				_add("gpa", 3.0)
			_add("stress", 4.0)
			_add("energy", -4.0)
			var mode: String = event_mode.get("mode", "assignment")
			if mode == "assignment" and event_mode.has("assign_day"):
				assignments_done[event_mode["assign_day"]] = true
			toast_message = "%s: %d/5 perfect taps. Handed in!" % [_title_for_event(), g]
		"rush":
			var hits: int = results.get("hits", 0)
			_add("stress", float(hits) * 4.0)
			_add("energy", -4.0)
			_add("gpa", 2.0)
			if hits == 0:
				toast_message = "Sprinted into lecture geese-free and on time! GPA +2"
			else:
				toast_message = "Made it to class (geese: %d hits, dignity: damaged). GPA +2" % hits
	event_mode = {}
	_after_action()
	return _next_scene_after_event()

func _title_for_event() -> String:
	## For essay events we use a nicer shorthand for the toast.
	match event_mode.get("mode", ""):
		"assignment": return "Assignment"
		"standup": return "Stand-Up Sprint"
		"pavlova": return "Pavlova Panel"
	return "Task"

func _next_scene_after_event() -> String:
	if lost_reason != "":
		return "res://scenes/lose.tscn"
	if exam_taken and gpa >= PASS_GPA:
		return "res://scenes/win.tscn"
	return "res://scenes/campus.tscn"

## Campus-side helper: after a plain (non-minigame) action, which screen?
func next_scene_after_action() -> String:
	if lost_reason != "":
		return "res://scenes/lose.tscn"
	return "res://scenes/campus.tscn"
