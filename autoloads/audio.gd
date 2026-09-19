extends Node
## AudioFx: one autoload that owns all sound. SFX are pooled one-shots
## (so hits can overlap), music is a crossfading pair of players.
## Sources are the files in assets/audio/ - all Kenney CC0 + Kevin MacLeod
## CC-BY (attribution recorded in ASSETS.md and README).

const SFX_INDEX := {
    "click": "res://assets/audio/sfx_click.ogg",
    "hover": "res://assets/audio/sfx_hover.ogg",
    "select": "res://assets/audio/sfx_select.ogg",
    "confirm": "res://assets/audio/sfx_confirm.ogg",
    "back": "res://assets/audio/sfx_back.ogg",
    "correct": "res://assets/audio/sfx_correct.ogg",
    "wrong": "res://assets/audio/sfx_wrong.ogg",
    "tick": "res://assets/audio/sfx_tick.ogg",
    "switch": "res://assets/audio/sfx_switch.ogg",
}

const MUSIC_INDEX := {
    "menu": "res://assets/audio/music_menu.mp3",
    "campus": "res://assets/audio/music_campus.mp3",
    "focus": "res://assets/audio/music_focus.mp3",
}

const SFX_DB := -4.0
const MUSIC_DB := -16.0
const CROSSFADE := 0.9

var _sfx_streams := {}        # name -> AudioStream (loaded once)
var _music_streams := {}
var _pool: Array = []
var _pool_i := 0
var _music := []              # two AudioStreamPlayers, crossfades between
var _music_i := 0
var _current_music := ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for name in SFX_INDEX:
        _sfx_streams[name] = load(SFX_INDEX[name])
    for name in MUSIC_INDEX:
        _music_streams[name] = load(MUSIC_INDEX[name])
    for i in 8:
        var p := AudioStreamPlayer.new()
        p.bus = "Master"
        p.volume_db = SFX_DB
        add_child(p)
        _pool.append(p)
    for i in 2:
        var p := AudioStreamPlayer.new()
        p.volume_db = MUSIC_DB
        p.process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(p)
        _music.append(p)

## Play a named one-shot SFX.
func sfx(name: String) -> void:
    if not _sfx_streams.has(name):
        return
    var p: AudioStreamPlayer = _pool[_pool_i]
    _pool_i = (_pool_i + 1) % _pool.size()
    p.stream = _sfx_streams[name]
    p.play()

## Crossfade to a named music loop. Same track = no-op.
func music(name: String) -> void:
    if name == _current_music:
        return
    if not _music_streams.has(name):
        return
    var from: AudioStreamPlayer = _music[_music_i]
    var to: AudioStreamPlayer = _music[(1 - _music_i) % 2]
    to.stream = _music_streams[name]
    to.volume_db = MUSIC_DB
    to.play()
    var tw := create_tween()
    tw.tween_property(from, "volume_db", MUSIC_DB - 30.0, CROSSFADE)
    tw.parallel().tween_property(to, "volume_db", MUSIC_DB, CROSSFADE)
    tw.tween_callback(func() -> void: from.stop())
    _music_i = (1 - _music_i) % 2
    _current_music = name

func _notification(what: int) -> void:
    # Only fire the pause when the whole tree pauses (game popup pause).
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _current_music = ""