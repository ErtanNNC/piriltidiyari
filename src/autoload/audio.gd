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
	"chapter5": "castle", "final": "festival", "preview": "village",
	"s3_scene1": "festival", "s3_scene2": "pus",
	"s3_scene3": "pus", "s3_scene4": "tower", "s3_scene5": "tower", "s3_scene6": "village", "s3_chapter0": "village", "s3_chapter1": "cave", "s3_chapter2": "harbor", "s3_chapter3": "forest", "s3_chapter4": "mountain", "s3_chapter5": "castle", "s3_final": "festival", "s3_regatta": "harbor", "s3_garden": "cave",
	"s2_scene1": "festival", "s2_scene2": "pus", "s2_scene3": "mountain", "s2_scene4": "tower",
	"s2_scene5": "tower", "s2_scene6": "village", "s2_chapter0": "village", "s2_chapter1": "forest", "s2_chapter2": "harbor", "s2_chapter3": "festival", "s2_chapter4": "mountain", "s2_chapter5": "castle", "s2_final": "festival",
}
## A quiet ambience loop under the music (Oculus Audio Pack recordings in
## assets/audio/ambience): forest birds, the lake shore, the sea, a farm,
## bubbling hot springs, a creek, night crickets. On the Sfx bus, so the
## effects switch mutes it too.
const AMBIENCE_DIR := "res://assets/audio/ambience/"
const SCENE_AMBIENCE := {
	"scene1": "creek", "chapter0": "creek", "chapter1": "forest", "chapter3": "sea",
	"s3_scene1": "sea", "s3_scene2": "sea",
	"s3_scene3": "sea", "s3_scene4": "sea", "s3_scene5": "sea", "s3_scene6": "sea", "s3_chapter0": "sea", "s3_chapter1": "sea", "s3_chapter2": "sea", "s3_chapter3": "sea", "s3_chapter4": "sea", "s3_chapter5": "sea", "s3_final": "sea", "s3_regatta": "sea", "s3_garden": "lake",
	"s2_scene1": "creek", "s2_chapter0": "springs", "s2_chapter1": "forest",
	"s2_chapter2": "lake", "s2_chapter3": "farm", "s2_final": "creek", "final": "creek",
}
const AMBIENCE_DB := -17.0
## the recordings differ in loudness: dB added per loop so each is heard
const AMBIENCE_LEVEL := {"forest": 8.0, "sea": -1.0}
## per-sound loudness in dB (0 = as generated) and how much the pitch may wander
const LEVEL := {"blip": -9.0, "click": -6.0, "pop": -6.0, "warn": -9.0, "land": -8.0,
	"jump": -5.0, "jump2": -5.0, "swish": -4.0, "roll": -5.0, "hit": -2.0, "coin": -5.0,
	"wind": -6.0, "splash": -6.0, "card": -4.0, "fanfare": -3.0, "boss_calm": -3.0,
	"calm": -4.0, "memory": -4.0, "laugh": -5.0, "page": -4.0, "drum": -7.0, "shop": -5.0,
	"sleep": -8.0, "fall": -7.0, "stone": -6.0, "heal": -6.0, "bell": -5.0, "crystal": -5.0,
	"quest": -3.0}
const PITCH_VAR := {"blip": 0.08, "hit": 0.1, "coin": 0.04, "swish": 0.08, "jump": 0.05,
	"land": 0.1, "click": 0.05, "pop": 0.08}
const MUSIC_DB := -9.0
const VOICES := 12

var music_on := true
var sfx_on := true
## Slider volumes 0..1 (Mola menu), applied to the Music / Sfx buses.
var music_volume := 0.8
var sfx_volume := 0.9
var _duck := 0.0

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
var _sfx_bus := 0
var _data: PlayerData
var _quiet_until := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_language()
	_music_bus = _bus("Music")
	_sfx_bus = _bus("Sfx")
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
	_amb = AudioStreamPlayer.new()
	_amb.bus = "Sfx"
	_amb.volume_db = -60.0
	add_child(_amb)
	# many loud sounds at once (bell + fanfare + music) must not clip the speaker
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, lim)
	_load_settings()
	AudioServer.set_bus_mute(_sfx_bus, not sfx_on)
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


func _process(delta: float) -> void:
	# the grey Pus muffles the music; lit lanterns open it up again
	var target := 20000.0 * pow(0.08, clampf(Pus.amount, 0.0, 1.0))
	_lowpass.cutoff_hz = lerpf(_lowpass.cutoff_hz, target, 0.05)
	# ducking: music dips while someone is talking, so words come first
	_duck = move_toward(_duck, 1.0 if GameState.in_dialogue else 0.0, delta * 3.0)
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(music_volume * music_volume, 0.0001)) + 1.9 - 7.0 * _duck)
	AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(maxf(sfx_volume * sfx_volume, 0.0001)) + 0.9)
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
		if GameState.data and GameState.data.quest_state(id) == "done":
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
	# a free voice first; only when all twelve ring is the oldest one cut
	var v := _voices[_next_voice]
	for i in VOICES:
		var c := _voices[(_next_voice + i) % VOICES]
		if not c.playing:
			v = c
			break
	_next_voice = (_voices.find(v) + 1) % VOICES
	v.stream = stream
	# a little loudness variety too, so repeats don't sound like a machine gun
	v.volume_db = float(LEVEL.get(sound, 0.0)) + db + randf_range(-1.5, 0.5)
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
	ambience(SCENE_AMBIENCE.get(scene_id, ""))


var _amb: AudioStreamPlayer
var _amb_name := ""


## Switch the ambience loop ("" = none), with a soft fade.
func ambience(loop_name: String) -> void:
	if loop_name == _amb_name:
		return
	_amb_name = loop_name
	if loop_name == "" or not sfx_on:
		_fade(_amb, -60.0, 0.8, true)
		return
	var s := _stream(AMBIENCE_DIR + loop_name + ".ogg")
	if s == null:
		return
	_amb.stream = s
	_amb.volume_db = -60.0
	_amb.play()
	_fade(_amb, AMBIENCE_DB + float(AMBIENCE_LEVEL.get(loop_name, 0.0)), 1.5, false)


func boss(on: bool) -> void:
	if on == _in_boss:
		return
	_in_boss = on
	music("boss" if on else _scene_track)


func music(track: String, fade := 1.2) -> void:
	if track == _track and (not music_on or _music[_active].playing):
		return
	_track = track
	var old := _music[_active]
	_active = 1 - _active
	var cur := _music[_active]
	if old.playing:
		_fade(old, -60.0, fade, true)
	if track == "" or not music_on:
		return
	var s := _stream(MUSIC_DIR + track + ".ogg")
	if s == null:
		return
	cur.stream = s
	cur.volume_db = -60.0
	cur.play()
	_fade(cur, MUSIC_DB, fade, false)


var _fades: Dictionary = {}


## One volume fade per player at a time (a new fade replaces the old one).
func _fade(p: AudioStreamPlayer, to_db: float, seconds: float, stop_after: bool) -> void:
	var old: Tween = _fades.get(p)
	if old and old.is_valid():
		old.kill()
	var tw := create_tween()
	tw.tween_property(p, "volume_db", to_db, seconds)
	if stop_after:
		tw.tween_callback(p.stop)
	_fades[p] = tw


## Silence every music player right away (Müzik: Kapalı).
func _stop_music(seconds := 0.35) -> void:
	for p in _music:
		if p.playing:
			_fade(p, -60.0, seconds, true)


# --- settings -----------------------------------------------------------------

func set_music_on(on: bool) -> void:
	music_on = on
	if on:
		# start what this place should play (the boss track during a fight)
		var t := "boss" if _in_boss else (_track if _track != "" else _scene_track)
		_track = ""
		music(t, 0.6)
	else:
		_stop_music()
	_save_settings()


func set_sfx_on(on: bool) -> void:
	sfx_on = on
	AudioServer.set_bus_mute(_sfx_bus, not on)
	var a := _amb_name
	_amb_name = ""
	if on:
		ambience(a)
	else:
		_fade(_amb, -60.0, 0.3, true)
		_amb_name = a
	_save_settings()


## Game language: "tr" (the source text) or "en" (translations/en.po).
## First run follows the phone's language: Turkish phones get Turkish,
## everyone else English.
var language := ""


func set_language(code: String) -> void:
	language = code
	_apply_language()
	_save_settings()


func _apply_language() -> void:
	if language == "":
		var c := ConfigFile.new()
		if c.load(SETTINGS) == OK:
			language = String(c.get_value("genel", "dil", ""))
	if language == "":
		language = "tr" if OS.get_locale_language() == "tr" else "en"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			language = arg.get_slice("=", 1)
	TranslationServer.set_locale(language)


func _load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(SETTINGS) == OK:
		music_on = bool(c.get_value("ses", "muzik", true))
		sfx_on = bool(c.get_value("ses", "efekt", true))
		music_volume = float(c.get_value("ses", "muzik_seviye", 0.8))
		sfx_volume = float(c.get_value("ses", "efekt_seviye", 0.9))


func _save_settings() -> void:
	var c := ConfigFile.new()
	c.set_value("ses", "muzik", music_on)
	c.set_value("ses", "efekt", sfx_on)
	c.set_value("ses", "muzik_seviye", music_volume)
	c.set_value("ses", "efekt_seviye", sfx_volume)
	c.set_value("genel", "dil", language)
	c.save(SETTINGS)


func set_volumes(music_v: float, sfx_v: float) -> void:
	music_volume = clampf(music_v, 0.0, 1.0)
	sfx_volume = clampf(sfx_v, 0.0, 1.0)
	_save_settings()
