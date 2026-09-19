extends Control
## Quiz engine: multiple-choice minigame.
## Used for: pop quizzes (Day 2/4), the three degree events that use quiz
## mechanics, the MUITSA Quiz Night, and the finals BOSS exam.
## Reads GameState.event_mode for {type, category, title, blurb}.
## type == "exam" adds a shrinking answer timer per question.
## Feedback juice: correct answers flash gold+green, wrong answers flash red;
## the right answer is highlighted before moving on.

enum State { WAIT, FEEDBACK, DONE }

const DELAY_AFTER_CORRECT := 0.8
const DELAY_AFTER_WRONG := 1.6

var state := State.WAIT
var questions: Array = []
var index := 0
var correct := 0
var feedback_timer := 0.0
var exam_time := 0.0
var time_limit := 0.0
var buttons: Array = []

var title_lbl: Label
var blurb_lbl: Label
var q_lbl: Label
var feedback_lbl: Label
var results_lbl: Label
var options_box: VBoxContainer
var timer_bar: ColorRect
var is_exam := false

func _ready() -> void:
    theme = UiKit.theme()
    UiKit.backdrop(self)
    UiKit.fade_in(self)
    AudioFx.music("focus")
    _build_static_ui()
    var mode := GameState.event_mode
    is_exam = mode.get("type", "") == "exam"
    title_lbl.text = "FINAL EXAMS" if is_exam else mode.get("title", "QUIZ!")
    blurb_lbl.text = mode.get("blurb", "")
    questions = _question_bank(mode.get("category", "general"), is_exam)
    _show_question()

func _build_static_ui() -> void:
    title_lbl = UiKit.label("", 32, Palette.GOLD, true, 800)
    title_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title_lbl.position = Vector2(0, 40)
    title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(title_lbl)

    blurb_lbl = UiKit.label("", 15, Palette.LIGHT, false, 500)
    blurb_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
    blurb_lbl.position = Vector2(0, 90)
    add_child(blurb_lbl)

    q_lbl = UiKit.label("", 25, Palette.PAPER, false, 600)
    q_lbl.anchor_left = 0.0
    q_lbl.anchor_right = 1.0
    q_lbl.offset_left = 140
    q_lbl.offset_right = -140
    q_lbl.offset_top = 170
    q_lbl.offset_bottom = 290
    q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(q_lbl)

    options_box = VBoxContainer.new()
    options_box.anchor_left = 0.5
    options_box.anchor_right = 0.5
    options_box.offset_left = -420
    options_box.offset_right = 420
    options_box.offset_top = 300
    options_box.add_theme_constant_override("separation", 14)
    add_child(options_box)

    feedback_lbl = UiKit.label("", 24, Palette.PAPER, false, 700)
    feedback_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    feedback_lbl.position = Vector2(0, -150)
    add_child(feedback_lbl)

    results_lbl = UiKit.label("", 34, Palette.GOLD, true, 800)
    results_lbl.set_anchors_preset(Control.PRESET_CENTER)
    results_lbl.anchor_left = 0.5
    results_lbl.anchor_right = 0.5
    results_lbl.offset_left = -400
    results_lbl.offset_right = 400
    results_lbl.offset_top = 250
    results_lbl.offset_bottom = 330
    results_lbl.hide()
    add_child(results_lbl)

    timer_bar = ColorRect.new()
    timer_bar.color = Palette.GOLD
    timer_bar.anchor_left = 0.5
    timer_bar.anchor_right = 0.5
    timer_bar.offset_left = -420
    timer_bar.offset_right = 420
    timer_bar.offset_top = 280
    timer_bar.offset_bottom = 294
    add_child(timer_bar)

func _show_question() -> void:
    feedback_lbl.text = ""
    timer_bar.hide()
    if index >= questions.size():
        _finish()
        return
    var q: Dictionary = questions[index]
    q_lbl.text = "Q%d: %s" % [index + 1, q["q"]]
    for child in options_box.get_children():
        options_box.remove_child(child)
        child.queue_free()
    buttons.clear()
    for c in range(q["choices"].size()):
        var btn := UiKit.button("%c. %s" % ["ABCD"[c], q["choices"][c]], Vector2(840, 54), 18, 600)
        btn.add_theme_stylebox_override("normal", UiKit.box(Color("#12365f"), 10))
        btn.add_theme_stylebox_override("hover", UiKit.box(Palette.BLUE, 10))
        btn.add_theme_stylebox_override("pressed", UiKit.box(Palette.LIGHT, 10))
        btn.add_theme_color_override("font_color", Palette.PAPER)
        btn.add_theme_color_override("font_hover_color", Palette.PAPER)
        btn.add_theme_color_override("font_pressed_color", Palette.DARK)
        btn.pressed.connect(_pick_answer.bind(c))
        options_box.add_child(btn)
        buttons.append(btn)
    if is_exam:
        exam_time = 0.0
        time_limit = maxf(4.5, 9.5 - index * 1.2)
        timer_bar.show()
    state = State.WAIT

func _pick_answer(choice: int) -> void:
    if state != State.WAIT:
        return
    var q: Dictionary = questions[index]
    var timed_out: bool = choice == -1
    var got_it: bool = (not timed_out) and choice == q["correct"]
    var delay := DELAY_AFTER_WRONG

    if got_it:
        correct += 1
        feedback_lbl.text = "Correct! (+3 GPA incoming)"
        feedback_lbl.add_theme_color_override("font_color", Palette.SAGE)
        _mark_button(choice, true)
        UiKit.burst(self, _button_center(choice), Palette.GOLD, 14)
        AudioFx.sfx("correct")
        delay = DELAY_AFTER_CORRECT
    else:
        if timed_out:
            feedback_lbl.text = "Time's up! It was: %s" % q["choices"][q["correct"]]
        else:
            feedback_lbl.text = "Wrong! It was: %s" % q["choices"][q["correct"]]
        feedback_lbl.add_theme_color_override("font_color", Palette.RED)
        if not timed_out:
            _mark_button(choice, false)
        _mark_button(q["correct"], true)
        UiKit.flash(self, Palette.RED, 0.22)
        AudioFx.sfx("wrong")
        delay = DELAY_AFTER_WRONG

    if got_it:
        UiKit.burst(self, _button_center(q["correct"]), Palette.BRIGHT, 10)
    state = State.FEEDBACK
    feedback_timer = delay

## Green or red fill on a chosen answer button.
func _mark_button(idx: int, is_correct: bool) -> void:
    if idx < 0 or idx >= buttons.size():
        return
    var btn: Button = buttons[idx]
    var col := Palette.SAGE if is_correct else Palette.RED
    btn.add_theme_stylebox_override("normal", UiKit.box(col, 10))
    btn.add_theme_color_override("font_color", Palette.DARK if is_correct else Palette.PAPER)
    btn.scale = Vector2(1.02, 1.02)

func _button_center(idx: int) -> Vector2:
    if idx < 0 or idx >= buttons.size():
        return Vector2(640, 360)
    var btn: Control = buttons[idx]
    return btn.global_position + btn.size * 0.5

func _process(delta: float) -> void:
    if state == State.WAIT:
        if is_exam:
            exam_time += delta
            timer_bar.size.x = (1.0 - exam_time / time_limit) * 840.0
            if exam_time >= time_limit:
                _pick_answer(-1)
        else:
            for c in range(4):
                if Input.is_physical_key_pressed(KEY_1 + c):
                    _pick_answer(c)
    elif state == State.FEEDBACK:
        feedback_timer -= delta
        if feedback_timer <= 0.0:
            index += 1
            _show_question()

func _finish() -> void:
    state = State.DONE
    results_lbl.text = "%d / %d correct" % [correct, questions.size()]
    results_lbl.show()
    UiKit.pop_in(results_lbl)
    AudioFx.sfx("confirm")
    var next: String = GameState.finish_event({"correct": correct, "total": questions.size()})
    await get_tree().create_timer(1.5).timeout
    UiKit.fade_and_switch(self, next)

## Question banks. Academic answers are textbook-accurate; wrong answers are
## absurd/deadpan on purpose (never plausible distractors). The FINALS route
## by degree (hardest, 6 questions); the CS/Vet mid-run events use lighter
## drill banks; general/MUITSA stay campus-life jokes.
func _question_bank(category: String, is_exam: bool) -> Array:
    if is_exam:
        match GameState.degree:
            "Computer Science": return _cs_final()
            "Software Engineering": return _se_final()
            "Veterinary Science": return _vet_final()
            _: return _food_final()
    match category:
        "cs": return _cs_drill()
        "vet": return _vet_drill()
        "muitsa": return _muitsa_bank()
        _: return _general_bank()


## Computer Science: mid-run drill (Sunday Night Segfault event).
func _cs_drill() -> Array:
    return [
        {"q": "What is an unsigned integer?", "choices": [
            "A whole number that can only be zero or positive",
            "An integer whose last text to the negatives was left on read",
            "A number currently mid-separation from Decimal",
            "The professor's reasoning for the six-question final"], "correct": 0},
        {"q": "Which sorting algorithm has an average runtime of O(n log n)?", "choices": [
            "Merge sort",
            "Bubble sort, which is O(n) because bubbles are light",
            "Dice sort: keep rolling until it looks sorted",
            "Goose sort: everyone is honked into alphabetical order"], "correct": 0},
        {"q": "A stack data structure processes items...", "choices": [
            "LIFO: the last item pushed is the first popped",
            "In order of emotional damage",
            "By queueing the campus geese into one orderly line",
            "By snack tier, judged nightly"], "correct": 0},
        {"q": "An off-by-one error in your loop means it...", "choices": [
            "Runs one too many or one too few times",
            "Eloped with the <= operator in secret",
            "Left town and is now a barista",
            "Is exactly one iteration of grief ahead of the class"], "correct": 0},
    ]


## Computer Science: hardest, 6 questions.
func _cs_final() -> Array:
    return [
        {"q": "A dictionary (hash map) stores data as...", "choices": [
            "Key-value pairs",
            "A respectful queue of pairs holding hands",
            "Pairs that agreed never to discuss what happened",
            "A flock of geese with name tags"], "correct": 0},
        {"q": "In Big-O terms, binary search on sorted data runs in...", "choices": [
            "O(log n)",
            "O(1) because the answer is always 'look it up'",
            "O(n squared) but with confidence",
            "O(eventually), defined precisely as 'when the build passes'"], "correct": 0},
        {"q": "Encapsulation in OOP means...", "choices": [
            "Bundling data with the methods that use it and hiding the internals",
            "Wrapping your laptop in bubble wrap for the commute",
            "A method that refuses to discuss its feelings",
            "Storing every password in a file named 'definitely-not-passwords'"], "correct": 0},
        {"q": "Which transport protocol is connectionless and offers no delivery guarantee?", "choices": [
            "UDP",
            "TCP, which explains how the Wi-Fi ghosts you",
            "SMTP, which stands for 'Sorry My Toaster Malfunctioned'",
            "The protocol the geese use to be menacing"], "correct": 0},
        {"q": "A deadlock happens when...", "choices": [
            "Two processes each hold a resource the other needs, so neither proceeds",
            "The code is simply too polite to interrupt",
            "The compiler and the linter refuse to share the office",
            "The documentation goes on strike"], "correct": 0},
        {"q": "A null pointer dereference is...", "choices": [
            "Using a null reference to access the memory it doesn't point to",
            "A ghost haunting the debugger",
            "The professor checking your repository",
            "The stack getting its feelings hurt"], "correct": 0},
    ]


## Software Engineering: hardest, 6 questions.
func _se_final() -> Array:
    return [
        {"q": "In TDD, the loop is...", "choices": [
            "Red, green, refactor",
            "Write it, call it done, deny everything",
            "Red, pray, deploy",
            "Merge, run, weep"], "correct": 0},
        {"q": "The 'definition of done' is...", "choices": [
            "A shared, agreed list of criteria for calling work finished",
            "Whatever the stand-up got bored of",
            "The scrum master's answer at 4:59pm",
            "A blank canvas, emotionally speaking"], "correct": 0},
        {"q": "A burndown chart tracks...", "choices": [
            "Remaining work against time in the sprint",
            "How toasted the clubroom toaster gets each day",
            "Team morale across a Tuesday",
            "How many times 'done' was said in stand-up"], "correct": 0},
        {"q": "Continuous integration means...", "choices": [
            "Automatically building and testing on every integration",
            "Merging, then running, then weeping in the car",
            "A weekly meeting about whether to meet",
            "Integration, occasionally, at one's leisure"], "correct": 0},
        {"q": "Technical debt is...", "choices": [
            "The rework cost of shortcuts taken now that you pay back later",
            "What the dev team owes the coffee stand",
            "An invoice from the tabs you left open",
            "The bug folder ritually labelled 'blessed'"], "correct": 0},
        {"q": "Which design pattern creates objects without exposing the creation logic?", "choices": [
            "Factory",
            "The Pattern That Was Definitely In The Slides",
            "Builder, Bicyclist and the Bystander pattern",
            "The Goose pattern (objects are created through intimidation)"], "correct": 0},
    ]


## Veterinary Science: mid-run drill (Great Llama Upheaval event).
func _vet_drill() -> Array:
    return [
        {"q": "Which animal is an obligate carnivore - it must eat animal tissue to survive?", "choices": [
            "The domestic cat",
            "The vending machine",
            "A goat with strong opinions about kale",
            "Your flatmate, who is allergic to breakfast"], "correct": 0},
        {"q": "Why can't horses vomit?", "choices": [
            "Anatomy: a strong cardiac sphincter plus a long neck make it practically impossible",
            "They signed consent forms as foals",
            "Their gag reflex is unionised and on strike",
            "They're too polite to complain"], "correct": 0},
        {"q": "How many stomachs does a cow have?", "choices": [
            "One stomach with four chambers: rumen, reticulum, omasum, abomasum",
            "Four separate stomachs that each file their own taxes",
            "Two - one for pasture, one for lunch",
            "Zero; cows photosynthesise like houseplants"], "correct": 0},
        {"q": "A dog's pregnancy lasts about...", "choices": [
            "63 days (roughly two months)",
            "Nine months, aligned to your assignment calendar",
            "Four minutes - they move fast",
            "Until the Wi-Fi drops, after which it stays"], "correct": 0},
    ]


## Veterinary Science: hardest, 6 questions.
func _vet_final() -> Array:
    return [
        {"q": "In a ruminant, the 'true stomach' - most like a human's - is the...", "choices": [
            "Abomasum",
            "Rumen, the midnight-snacking chamber",
            "The one holding the Wi-Fi router",
            "All of them, fraudulently"], "correct": 0},
        {"q": "A disease that passes between animals and humans is called...", "choices": [
            "Zoonotic",
            "Dramatic",
            "A networking event",
            "Thursday"], "correct": 0},
        {"q": "A cat in pain will commonly...", "choices": [
            "Hide, stop eating and growl",
            "Post passive-aggressive sticky notes",
            "Refuse to acknowledge the incident",
            "File a complaint with the toaster lobby"], "correct": 0},
        {"q": "Which of these is a ruminant that chews cud?", "choices": [
            "Cow",
            "Dog",
            "The student council",
            "A goose with a clipboard"], "correct": 0},
        {"q": "Newborn kittens are born with...", "choices": [
            "Closed eyes that open around 7-10 days old",
            "A graduation certificate",
            "Strong opinions about your course load",
            "A full driver's licence (unusual)"], "correct": 0},
        {"q": "Fleas are a type of...", "choices": [
            "External parasite",
            "Interior decorator",
            "Campus Wi-Fi manager",
            "Pre-existing condition"], "correct": 0},
    ]


## Food Science: hardest, 6 questions.
func _food_final() -> Array:
    return [
        {"q": "Emulsification lets oil and water blend because...", "choices": [
            "An emulsifier coats the droplets so they stay suspended",
            "Enough blender RPM temporarily overrides physics",
            "The oil and water agreed to disagree calmly",
            "Mayonnaise itself is a wizard"], "correct": 0},
        {"q": "Salt preserves food mainly by...", "choices": [
            "Drawing water out (osmosis) so microbes can't thrive",
            "Bribing the microbes",
            "Annoying the microbes into resigning",
            "Adding strict digital rights management"], "correct": 0},
        {"q": "Low-acid canned food must be pressure-canned at a precise time and temperature to prevent...", "choices": [
            "Botulism from Clostridium botulinum spores",
            "The potatoes achieving sentience",
            "Rust sneaking in through the seams",
            "Spontaneously becoming soup"], "correct": 0},
        {"q": "Gluten gives dough its...", "choices": [
            "Elasticity, from the glutenin and gliadin proteins",
            "Ability to hold a grudging silence",
            "Deep personal conviction",
            "A strict 9-to-5 schedule"], "correct": 0},
        {"q": "The body makes vitamin D when...", "choices": [
            "Sunlight hits your skin",
            "You reheat leftovers four times in a row",
            "The vending machine's glow reaches 500 lux",
            "You stare at the projector screen long enough"], "correct": 0},
        {"q": "Yeast fermenting sugars produces...", "choices": [
            "Ethanol and carbon dioxide",
            "A polite suggestion",
            "Smaller sugars with harder attitudes",
            "A certified financial advisor"], "correct": 0},
    ]


## Campus-life jokes for the MUITSA quiz night (unchanged).
func _muitsa_bank() -> Array:
    return [
        {"q": "The MUITSA clubroom's most sacred law:", "choices": ["The toaster stays. No exceptions", "Projector at 60Hz or watch the revolution", "No shoes on the beanbag of power", "Respect the temp password - it's been there since Semester One"], "correct": 0},
        {"q": "At LAN night, the official snack is:", "choices": ["Toast and meme-brand cheese", "Muesli bars with RGB lighting", "Instant ramen, but only on a corporate allowance", "Whatever the geese left"], "correct": 1},
        {"q": "You spot smoke rising from the server rack:", "choices": ["Panic professionally", "Take a photo for the incident report", "Unplug the internet and apologise to everyone", "Declare it a llama-free zone and rejoice"], "correct": 0},
    ]


## Campus-life pop quiz bank (unchanged) - degree-agnostic.
func _general_bank() -> Array:
    return [
        {"q": "The library's famous spiral staircase is also:", "choices": ["The finest place to quietly combust on campus", "A portal to the shadow library", "Actually a slide in disguise", "Grounds for a scholarship in stair-math"], "correct": 0},
        {"q": "The campus geese have unionised. Their core demand:", "choices": ["Daily bread, any brand of bread, bread", "A rework of the parking plan", "Free reign of the quad after 5pm", "A mascot spin-off series"], "correct": 0},
        {"q": "Your group project partner says 'all done'. The test:", "choices": ["Open the file and brace for impact", "Trust them - shockingly, it's done", "Ask the geese to arbitrate", "Scream quietly into the spiral staircase"], "correct": 0},
        {"q": "Best post-lecture survival strategy:", "choices": ["Nap first, caffeinate later, think never", "Write your memoir of the lecture", "Form a study group with 47 strangers", "Just vibes"], "correct": 2},
        {"q": "The Food Hall's 'meme sandwich' contains:", "choices": ["Bread, despair, and one free pickle", "A QR code to a goose opinions podcast", "A perfect 50/50 split of regret", "The answer to next week's pop quiz"], "correct": 0},
    ]