extends Node
## Music and sound effects. All audio files are made by tools/make_audio.py.

var _music: AudioStreamPlayer
var _song: AudioStreamPlayer
var _fx: Array[AudioStreamPlayer] = []
var _cache := {}
var _ducked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.volume_db = -9.0
	add_child(_music)
	_song = AudioStreamPlayer.new()
	add_child(_song)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_fx.append(p)


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## Plays a short sound: pop, boing, tap, chime, yay, twinkle, horn, swish, scrub, splash, wrong.
func sfx(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not Save.sound:
		return
	var s := _load("res://audio/sfx_%s.wav" % name)
	if s == null:
		return
	for p in _fx:
		if not p.playing:
			p.stream = s
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.play()
			return
	_fx[0].stream = s
	_fx[0].pitch_scale = pitch
	_fx[0].play()


func home_music(on: bool) -> void:
	if on and Save.music:
		if not _music.playing:
			var s := _load("res://audio/home_loop.ogg")
			if s == null:
				return
			s.loop = true
			_music.stream = s
			_music.play()
	else:
		_music.stop()


## Starts a song from the top. Returns false if the file is missing.
func play_song(id: String) -> bool:
	var s := _load("res://audio/song_%s.ogg" % id)
	if s == null:
		return false
	_song.stream = s
	_song.stream_paused = false
	_song.play()
	return true


func stop_song() -> void:
	_song.stop()


func pause_song(paused: bool) -> void:
	_song.stream_paused = paused


func song_playing() -> bool:
	return _song.playing and not _song.stream_paused


## Seconds into the current song, corrected for output delay so words light up on time.
func song_time() -> float:
	if not _song.playing:
		return -1.0
	return _song.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()


func song_length() -> float:
	return _song.stream.get_length() if _song.stream else 0.0


## Quietens everything while an ad is on screen.
func duck(on: bool) -> void:
	_ducked = on
	AudioServer.set_bus_mute(0, on)
