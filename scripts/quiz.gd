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
    title_lbl.text = "FINALS - Massey Uni Simulator" if is_exam else mode.get("title", "QUIZ!")
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

## The question bank. All questions are original jokes - no real people.
func _question_bank(category: String, is_exam: bool) -> Array:
    if is_exam:
        return [
            {"q": "Semester's over. The exam paper's big reveal is:", "choices": ["A joyful conclusion", "Three surprise sub-questions stapled in", "A single, merciful 'A+' in crayon", "All of the above, alphabetically sorted"], "correct": 1},
            {"q": "The invigilator's actual role is:", "choices": ["Ensuring justice with a stopwatch", "Making everyone anxious at a clipboard rate of 2000 words/min", "Cosplaying as a library", "Checking you hydrated enough to faint safely"], "correct": 2},
            {"q": "TIP: Loop through your answers in exam conditions:", "choices": ["Forward, obviously", "Backwards for luck", "With a while(true) and hope the invigilator ends it", "Only the ones you remember"], "correct": 0},
            {"q": "The old folk wisdom for finals is:", "choices": ["Coffee is a study aid", "Sleep is a study aid", "Coffee, then sleep, then more coffee, in that order, forever", "None of the above - geese solve everything"], "correct": 2},
            {"q": "You finish the last question. Best move:", "choices": ["Re-read every answer in a panic", "Stare at the ceiling like a philosopher", "Add a happy face", "White-knuckle the paper until someone takes it"], "correct": 1},
        ]
    match category:
        "cs":
            return [
                {"q": "The build server is on fire. The correct priority is:", "choices": ["Rebuild. It's ALWAYS the build", "Blame the geese in the change log", "Call the server a liar", "Push to main and flee"], "correct": 0},
                {"q": "Your loop runs zero times. The diagnosis is:", "choices": ["The condition is a sham", "Your IDE dislikes you personally", "The goblin in the back is eating the iterations", "Leap day"], "correct": 0},
                {"q": "It works on YOUR machine. Now what?", "choices": ["Ship it - that's proof", "Add a comment that it 'just works'", "Rerun it on the geese's machine", "Check for the one acid trip the compiler is hiding"], "correct": 0},
            ]
        "vet":
            return [
                {"q": "Llama 472 has escaped. Your capture tool of choice:", "choices": ["A large tuna sandwich (llamas love tuna, presumably)", "More llamas - the catalyst theory", "A lecture about consent", "Sheer, aggressive eye contact"], "correct": 0},
                {"q": "The sheep are all staring at you. Proper protocol:", "choices": ["Maintain eye contact back. Show dominance", "Offer a PowerPoint summary", "Bleat to establish a rapport", "Retreat - gather intel and the dishcloth"], "correct": 2},
                {"q": "A cow sneezed directly on your assignment,", "choices": ["Thank it for the constructive feedback", "Charge it for milk-based favours", "Frame it as the appendix", "Rerun the experiment on the sneeze itself"], "correct": 1},
            ]
        "muitsa":
            return [
                {"q": "The MUITSA clubroom's most sacred law:", "choices": ["The toaster stays. No exceptions", "Projector at 60Hz or watch the revolution", "No shoes on the beanbag of power", "Respect the temp password - it's been there since Semester One"], "correct": 0},
                {"q": "At LAN night, the official snack is:", "choices": ["Toast and meme-brand cheese", "Muesli bars with RGB lighting", "Instant ramen, but only on a corporate allowance", "Whatever the geese left"], "correct": 1},
                {"q": "You spot smoke rising from the server rack:", "choices": ["Panic professionally", "Take a photo for the incident report", "Unplug the internet and apologise to everyone", "Declare it a llama-free zone and rejoice"], "correct": 0},
            ]
        _:
            return [
                {"q": "The library's famous spiral staircase is also:", "choices": ["The finest place to quietly combust on campus", "A portal to the shadow library", "Actually a slide in disguise", "Grounds for a scholarship in stair-math"], "correct": 0},
                {"q": "The campus geese have unionised. Their core demand:", "choices": ["Daily bread, any brand of bread, bread", "A rework of the parking plan", "Free reign of the quad after 5pm", "A mascot spin-off series"], "correct": 0},
                {"q": "Your group project partner says 'all done'. The test:", "choices": ["Open the file and brace for impact", "Trust them - shockingly, it's done", "Ask the geese to arbitrate", "Scream quietly into the spiral staircase"], "correct": 0},
                {"q": "Best post-lecture survival strategy:", "choices": ["Nap first, caffeinate later, think never", "Write your memoir of the lecture", "Form a study group with 47 strangers", "Just vibes"], "correct": 2},
                {"q": "The Food Hall's 'meme sandwich' contains:", "choices": ["Bread, despair, and one free pickle", "A QR code to a goose opinions podcast", "A perfect 50/50 split of regret", "The answer to next week's pop quiz"], "correct": 0},
            ]