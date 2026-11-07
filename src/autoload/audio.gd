extends Node
## Music and sound effects. Files live in assets/audio (made by
## tools/make_audio.py; drop in a real recording with the same name to
## replace one). Music cross-fades per scene, switches to the boss track
## during fights and sounds muffled while the Pus is thick (a low-pass on the
## Music bus follows Pus.amount). Settings (music/effects on/off) are kept in
## user://ayarlar.cfg.
##   Audio.play("coin")      Audio.music("forest")      Audio.boss(true)

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const SETTINGS := "user://ayarlar.cfg"
const SCENE_MUSIC := {
	"title": "title", "scene1": "festival", "scene2": "pus", "scene3": "pus",
	"scene4": "tower", "scene5": "tower", "scene6": "village", "chapter0": "village",
	"chapter1": "forest", "chapter2": "cave", "chapter3": "harbor", "chapter4": "mountain",
	"chapter5": "castle", "final": "festival", "preview": "village", "house": "title",
}
## per-sound loudness in dB (0 = as generated) and how much the pitch may wander
const LEVEL := {"blip": -9.0, "click": -6.0, "pop": -6.0, "warn": -9.0, "land": -8.0,
	"jump": -5.0, "jump2": -5.0, "swish": -4.0, "roll": -5.0, "hit": -2.0, "coin": -5.0,
	"wind": -6.0, "splash": -6.0, "card": -4.0}
const PITCH_VAR := {"blip": 0.08, "hit": 0.1, "coin": 0.04, "swish": 0.08, "jump": 0.05,
	"land": 0.1, "click": 0.05, "pop": 0.08}
const MUSIC_DB := -9.0
const VOICES := 12

var music_on := true
var sfx_on := true

var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _track := ""
var _scene_track := ""
var _in_boss := false
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _streams: Dictionary = {}
var _last: Dictionary = {}
var _lowpass: AudioEffectLowPassFilter
var _music_bus := 0
var _data: PlayerData
var _quiet_until := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_bus = _bus("Music")
	_bus("Sfx")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(_music_bus, _lowpass)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -60.0
		add_child(p)
		_music.append(p)
	for i in VOICES:
		var v := AudioStreamPlayer.new()
		v.bus = "Sfx"
		add_child(v)
		_voices.append(v)
	_load_settings()
	GameState.toast.connect(func(_t: String, _i: String) -> void: play("pop"))
	GameState.shop_requested.connect(func(_id: String) -> void: play("shop"))


func _bus(n: String) -> int:
	var idx := AudioServer.get_bus_index(n)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, n)
		AudioServer.set_bus_send(idx, "Master")
	return idx


func _process(_delta: float) -> void:
	# the grey Pus muffles the music; lit lanterns open it up again
	var target := 20000.0 * pow(0.08, clampf(Pus.amount, 0.0, 1.0))
	_lowpass.cutoff_hz = lerpf(_lowpass.cutoff_hz, target, 0.05)
	if GameState.data != _data:
		_watch(GameState.data)


## Hooks the player's progress signals (a new game or a load swaps the data).
func _watch(d: PlayerData) -> void:
	_data = d
	if d == null:
		return
	_quiet_until = Time.get_ticks_msec() / 1000.0 + 0.5
	d.piril_changed.connect(func(_total: int, delta: int) -> void:
		if delta > 0:
			play("coin"))
	d.leveled_up.connect(func(_l: int) -> void: play("levelup"))
	d.quest_changed.connect(func(id: String) -> void:
		if d.quest_state(id) == "done":
			play("quest"))


# --- effects ------------------------------------------------------------------

func play(sound: String, db := 0.0) -> void:
	if not sfx_on:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < _quiet_until:
		return
	# the same sound twice within 60 ms (two mobs hit at once) plays once
	if now - float(_last.get(sound, -1.0)) < 0.06:
		return
	# a toast "pop" never stacks on top of a more specific sound
	if sound == "pop" and now - float(_last.get("_any", -1.0)) < 0.15:
		return
	_last[sound] = now
	if sound != "pop":
		_last["_any"] = now
	var stream := _stream(SFX_DIR + sound + ".wav")
	if stream == null:
		return
	var v := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	v.stream = stream
	v.volume_db = float(LEVEL.get(sound, 0.0)) + db
	var pv: float = PITCH_VAR.get(sound, 0.02)
	v.pitch_scale = randf_range(1.0 - pv, 1.0 + pv)
	v.play()


func _stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	elif s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_streams[path] = s
	return s


# --- music --------------------------------------------------------------------

func scene_changed(scene_id: String) -> void:
	_scene_track = SCENE_MUSIC.get(scene_id, _scene_track)
	_in_boss = false
	music(_scene_track)


func boss(on: bool) -> void:
	if on == _in_boss:
		return
	_in_boss = on
	music("boss" if on else _scene_track)


func music(track: String, fade := 1.2) -> void:
	if track == _track:
		return
	_track = track
	var old := _music[_active]
	_active = 1 - _active
	var cur := _music[_active]
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -60.0, fade)
		tw.tween_callback(old.stop)
	if track == "" or not music_on:
		return
	var s := _stream(MUSIC_DIR + track + ".ogg")
	if s == null:
		return
	cur.stream = s
	cur.volume_db = -60.0
	cur.play()
	var tw2 := create_tween()
	tw2.tween_property(cur, "volume_db", MUSIC_DB, fade)


# --- settings -----------------------------------------------------------------

func set_music_on(on: bool) -> void:
	music_on = on
	var t := _track
	_track = ""
	if on:
		music(t if t != "" else _scene_track, 0.6)
	else:
		music("", 0.4)
		_track = t
	_save_settings()


func set_sfx_on(on: bool) -> void:
	sfx_on = on
	_save_settings()


func _load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(SETTINGS) == OK:
		music_on = bool(c.get_value("ses", "muzik", true))
		sfx_on = bool(c.get_value("ses", "efekt", true))


func _save_settings() -> void:
	var c := ConfigFile.new()
	c.set_value("ses", "muzik", music_on)
	c.set_value("ses", "efekt", sfx_on)
	c.save(SETTINGS)
