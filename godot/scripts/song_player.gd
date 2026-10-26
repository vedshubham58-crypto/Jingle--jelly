extends Screen
## Sing-along: the song plays, the words light up one by one, Jelly sings,
## and things on screen react when tapped.

var arg: Variant = "twinkle"
var song: Dictionary = {}
var words: Array[Dictionary] = []  # {start, end, line, text}
var lines: Array = []  # Array of Array of word indexes
var jelly: Jelly
var cur := -1
var paused := false
var _started := false
var _done := false
var _fx: Array[Dictionary] = []  # floating sparkles / words
var _wheel_spin := 0.0
var _wheel_speed := 3.0
var _wiper := 0.0
var _horn := 0.0
var _animal_bounce := 0.0
var _road := 0.0
var _star_pulse := 0.0
var _bg_stars: Array[Vector2] = []


func _ready() -> void:
	_load_song(str(arg))
	jelly = Jelly.new()
	jelly.mood = "smile"
	add_child(jelly)
	super._ready()
	for i in 40:
		_bg_stars.append(Vector2(randf(), randf() * 0.62))
	Audio.home_music(false)
	_started = Audio.play_song(song.id)


func _load_song(id: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/songs.json"))
	for s in data.songs:
		if s.id == id:
			song = s
	if song.is_empty():
		song = data.songs[0]
	var beat := 60.0 / float(song.bpm)
	var time := float(song.lead_beats) * beat
	for li in song.lines.size():
		var idxs: Array = []
		for n in song.lines[li]:
			var dur := float(n[1]) * beat
			if str(n[2]) != "":
				idxs.append(words.size())
				words.append({"start": time, "end": time + dur, "line": li, "text": str(n[2]), "midi": int(n[0])})
			time += dur
		lines.append(idxs)


## Which word should be lit at [param time] (-1 before the first).
func word_at(time: float) -> int:
	var w := -1
	for i in words.size():
		if words[i].start <= time + 0.03:
			w = i
		else:
			break
	return w


func layout() -> void:
	add_back(func() -> void:
		Audio.stop_song()
		main.show_screen("songs"))
	add_button("pause", Rect2(W - 118, 30, 96, 96), func() -> void:
		paused = not paused
		Audio.pause_song(paused))
	jelly.size = 170
	jelly.position = Vector2(110, H - 330)


func tick(delta: float) -> void:
	var time := Audio.song_time()
	if not paused and _started:
		var w := word_at(time)
		if w != cur and w >= 0:
			cur = w
			_on_word(words[w])
	if _started and not paused and not _done and (time < 0 or time >= Audio.song_length() - 0.2) and t > 1.0:
		_done = true
		Audio.stop_song()
		var count: int = Save.songs_played.get(song.id, 0)
		Save.songs_played[song.id] = count + 1
		main.celebrate("songs")
	var bpm := float(song.bpm)
	if not paused:
		jelly.bob = Screen.hop(max(0.0, time), bpm, 14)
		_wheel_spin += _wheel_speed * delta
		_wheel_speed = lerp(_wheel_speed, 3.0, delta * 1.5)
		_road += delta * 220
	_wiper = max(0.0, _wiper - delta * 1.6)
	_horn = max(0.0, _horn - delta * 2.0)
	_animal_bounce = max(0.0, _animal_bounce - delta * 3.0)
	_star_pulse = max(0.0, _star_pulse - delta * 3.0)
	for f in _fx:
		f.p += f.v * delta
		f.v.y += f.g * delta
		f.a -= delta * f.fade
	_fx = _fx.filter(func(f: Dictionary) -> bool: return f.a > 0)


func _on_word(w: Dictionary) -> void:
	jelly.mouth_open = 1.0
	jelly.poke(0.12)
	var word: String = w.text.to_lower().trim_suffix(",").trim_suffix(".").trim_suffix("!")
	match song.id:
		"bus":
			if word == "round":
				_wheel_speed = 14.0
			elif word == "beep":
				_horn = 1.0
				_float_word("BEEP!", _horn_pos(), Draw.RED)
			elif word == "swish":
				_wiper = 1.0
		"farm":
			if word in ["moo", "quack", "oink"]:
				_animal_bounce = 1.0
				_float_word(word.capitalize() + "!", _animal_pos() + Vector2(randf_range(-90, 90), -220), Draw.PINK)
		"twinkle":
			_star_pulse = 1.0


func _float_word(s: String, p: Vector2, col: Color) -> void:
	_fx.append({"kind": "word", "s": s, "p": p, "v": Vector2(randf_range(-20, 20), -90), "g": 0.0, "a": 1.0, "fade": 0.9, "c": col})


func _sparkle(p: Vector2) -> void:
	for i in 6:
		var a := randf() * TAU
		_fx.append({"kind": "star", "p": p, "v": Vector2(cos(a), sin(a)) * randf_range(80, 220), "g": 120.0, "a": 1.0, "fade": 0.8, "c": [Draw.YELLOW, Color.WHITE, Draw.PINK].pick_random(), "r": randf_range(12, 26)})


func _bus_center() -> Vector2:
	return Vector2(W / 2 + 40, H * 0.47)


func _horn_pos() -> Vector2:
	return _bus_center() + Vector2(250, -10)


func _animal_pos() -> Vector2:
	return Vector2(W / 2 + 60, H * 0.56)


func _verse_animal() -> String:
	if cur < 0:
		return "cow"
	var li: int = words[cur].line
	var verses: Array = song.get("verses", ["cow"])
	return verses[clamp(int(li / 6), 0, verses.size() - 1)]


func press(p: Vector2) -> void:
	match song.id:
		"twinkle":
			Audio.sfx("twinkle", [1.0, 1.122, 1.26, 1.5][randi() % 4])
			_sparkle(p)
		"bus":
			var bc := _bus_center()
			for wx in [-170, 150]:
				if p.distance_to(bc + Vector2(wx, 120)) < 80:
					_wheel_speed = 18.0
					Audio.sfx("boing", 1.3)
					return
			if p.distance_to(_horn_pos()) < 90:
				_horn = 1.0
				Audio.sfx("horn")
				_float_word("BEEP!", _horn_pos(), Draw.RED)
				return
			if Rect2(bc + Vector2(150, -120), Vector2(110, 110)).grow(30).has_point(p):
				_wiper = 1.0
				Audio.sfx("swish")
				return
			_sparkle(p)
		"farm":
			if p.distance_to(_animal_pos()) < 160:
				_animal_bounce = 1.0
				var sound: String = {"cow": "Moo!", "duck": "Quack!", "pig": "Oink!"}[_verse_animal()]
				Audio.sfx("boing", randf_range(0.8, 1.1))
				_float_word(sound, _animal_pos() + Vector2(0, -220), Draw.PINK)
				return
			_sparkle(p)
	if p.distance_to(jelly.position + Vector2(0, -80)) < 100:
		jelly.poke(0.5)


func _draw() -> void:
	match song.id:
		"twinkle":
			_draw_night()
		"bus":
			_draw_bus_scene()
		_:
			_draw_farm()
	for f in _fx:
		if f.kind == "star":
			Draw.star(self, f.p, f.r, Color(f.c, f.a), t)
		else:
			Draw.text(self, f.p, f.s, 64, Color(f.c, f.a), Color(1, 1, 1, f.a), 14)
	_draw_lyrics()
	draw_back()
	var pb := button("pause")
	if not pb.is_empty():
		var r: Rect2 = pb.rect
		Draw.button_face(self, r, 48, Color.WHITE, pb.down)
		var c := r.get_center() + (Vector2(0, 10) if pb.down else Vector2.ZERO)
		if paused:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-12, -22), c + Vector2(-12, 22), c + Vector2(22, 0)]), Draw.GREEN)
		else:
			draw_rect(Rect2(c + Vector2(-18, -20), Vector2(12, 40)), Draw.INK)
			draw_rect(Rect2(c + Vector2(6, -20), Vector2(12, 40)), Draw.INK)
	Draw.text(self, Vector2(W / 2, 78), song.title, 46, Color.WHITE, Color(0, 0, 0, 0.35), 12)


func _draw_lyrics() -> void:
	var box := Rect2(30, H - 230, W - 60, 170)
	Draw.rounded_rect(self, Rect2(box.position + Vector2(0, 8), box.size), 40, Color(0, 0, 0, 0.12))
	Draw.rounded_rect(self, box, 40, Color.WHITE)
	if cur < 0:
		Draw.text(self, box.get_center(), "Get ready to sing!", 48, Draw.INK)
		return
	var li: int = words[cur].line
	var idxs: Array = lines[li]
	var size := 52
	# Long lines show one half at a time so the words stay big.
	if _line_width(idxs, size) > (box.size.x - 50) * 1.3 and idxs.size() > 3:
		var half := int(ceil(idxs.size() / 2.0))
		while half < idxs.size() - 1 and _joined(idxs[half - 1]):
			half += 1
		idxs = idxs.slice(0, half) if idxs.find(cur) < half else idxs.slice(half)
	var total := _line_width(idxs, size)
	if total > box.size.x - 50:
		size = int(size * (box.size.x - 50) / total)
		total = _line_width(idxs, size)
	var space := Draw.text_width(" ", size)
	var x := box.get_center().x - total / 2
	var y := box.get_center().y + 22
	var f := Draw.font()
	for i in idxs:
		var wtext: String = _shown(i)
		var ww := Draw.text_width(wtext, size)
		var col := Draw.INK
		if i == cur:
			col = Draw.PINK
			# Bouncing ball over the word being sung.
			var time := Audio.song_time()
			var k: float = clamp((time - words[i].start) / max(0.05, words[i].end - words[i].start), 0, 1)
			draw_circle(Vector2(x + ww / 2, y - size - 6 - sin(k * PI) * 22), 12, Draw.ORANGE)
		elif i > cur:
			col = Color("9aa3b5")
		draw_string(f, Vector2(x, y), wtext, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		x += ww + (0.0 if _joined(i) else space)


func _joined(i: int) -> bool:
	var w: String = words[i].text
	return w.ends_with("-") and w.length() > 2


## Syllables are written "Twin-" "kle"; show them joined as "Twinkle".
## Spelled-out letters ("E-" "I-" "O!") keep their dashes.
func _shown(i: int) -> String:
	var w: String = words[i].text
	return w if w.length() <= 2 else w.trim_suffix("-")


func _line_width(idxs: Array, size: int) -> float:
	var total := 0.0
	var space := Draw.text_width(" ", size)
	for i in idxs:
		total += Draw.text_width(_shown(i), size) + (0.0 if _joined(i) else space)
	return total - space


func _draw_night() -> void:
	Draw.gradient_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]), Color("1b1f5e"), Color("5b6cff"))
	for i in _bg_stars.size():
		var s := _bg_stars[i]
		var tw := 0.5 + 0.5 * sin(t * 2.0 + i * 1.7)
		Draw.star(self, Vector2(s.x * W, 140 + s.y * H), 5 + 6 * tw, Color(1, 1, 0.8, 0.5 + 0.5 * tw))
	draw_circle(Vector2(W - 150, 230), 70, Color("fff3b0"))
	draw_circle(Vector2(W - 115, 205), 62, Color("232a74"))
	# The big smiling star.
	var c := Vector2(W / 2, H * 0.36)
	var s := 150.0 * (1.0 + 0.12 * _star_pulse)
	for i in 8:
		var a := t * 0.3 + TAU * i / 8
		Draw.star(self, c + Vector2(cos(a), sin(a)) * s * 1.35, 14 + 6 * _star_pulse, Color(1, 0.95, 0.6, 0.8), t)
	Draw.star(self, c + Vector2(0, 8), s, Color("e6a800"), sin(t) * 0.06)
	Draw.star(self, c, s, Draw.YELLOW, sin(t) * 0.06)
	draw_circle(c + Vector2(-32, -6), 12, Draw.INK)
	draw_circle(c + Vector2(32, -6), 12, Draw.INK)
	draw_circle(c + Vector2(-28, -10), 4, Color.WHITE)
	draw_circle(c + Vector2(36, -10), 4, Color.WHITE)
	Draw.ellipse(self, c + Vector2(-56, 18), 14, 8, Draw.CHEEK)
	Draw.ellipse(self, c + Vector2(56, 18), 14, 8, Draw.CHEEK)
	Draw.ellipse(self, c + Vector2(0, 26), 16, 10 + 12 * _star_pulse, Color("8a4b00"))
	# Hill for Jelly.
	draw_colored_polygon(_hill(H - 380, 50), Color("2b3a8f"))
	Draw.text(self, Vector2(W / 2 + 70, H - 270), "Tap the sky to make stars!", 30, Color(1, 1, 1, 0.8))


func _draw_bus_scene() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("8fd8ff"))
	draw_circle(Vector2(110, 230), 60, Color("fff07a"))
	for i in 3:
		var cx := fmod(150.0 + i * 260 - t * 25, W + 200) - 100
		for k in 3:
			draw_circle(Vector2(cx + k * 40, 300 + i * 40 - (k % 2) * 18), 34, Color(1, 1, 1, 0.9))
	draw_colored_polygon(_hill(H * 0.42, 80), Color("8fe06a"))
	var road := Rect2(0, H * 0.56, W, 190)
	draw_rect(road, Color("596079"))
	for i in 8:
		var x := fmod(i * 140.0 - _road, W + 140)
		if x < -100:
			x += W + 140
		draw_rect(Rect2(x - 40, road.get_center().y - 6, 80, 12), Color.WHITE)
	draw_rect(Rect2(0, road.end.y, W, H - road.end.y), Color("6fcf4a"))
	var bc := _bus_center() + Vector2(0, Screen.hop(max(0.0, Audio.song_time()), float(song.bpm), 8))
	# Body.
	var body := Rect2(bc + Vector2(-290, -150), Vector2(560, 260))
	Draw.rounded_rect(self, Rect2(body.position + Vector2(0, 10), body.size), 50, Color("e0a800"))
	Draw.rounded_rect(self, body, 50, Draw.YELLOW)
	draw_rect(Rect2(body.position + Vector2(10, 170), Vector2(body.size.x - 20, 20)), Draw.ORANGE)
	# Windows with the family looking out.
	var faces := [Draw.SKIN, Draw.SKIN, Color("c9a27a")]
	for i in 3:
		var wr := Rect2(body.position + Vector2(30 + i * 130, 30), Vector2(110, 110))
		Draw.rounded_rect(self, wr, 18, Color("d6f2ff"))
		var fc := wr.get_center() + Vector2(0, 18 + sin(t * 4 + i) * 4)
		draw_circle(fc, 36, faces[i])
		if i == 2:
			Draw.ellipse(self, fc + Vector2(-34, -6), 12, 22, Color("8a6a4a"))
			Draw.ellipse(self, fc + Vector2(34, -6), 12, 22, Color("8a6a4a"))
			draw_circle(fc + Vector2(0, 10), 7, Draw.INK)
		elif i == 1:
			Draw.ellipse(self, fc + Vector2(0, -26), 38, 18, Color("7a4a2a"))
			draw_circle(fc + Vector2(-34, -6), 12, Color("7a4a2a"))
			draw_circle(fc + Vector2(34, -6), 12, Color("7a4a2a"))
		else:
			draw_arc(fc + Vector2(4, -36), 10, PI, TAU * 0.9, 10, Color("8a5a2b"), 5)
		draw_circle(fc + Vector2(-12, -4), 5, Draw.INK)
		draw_circle(fc + Vector2(12, -4), 5, Draw.INK)
		draw_arc(fc + Vector2(0, 6), 10, 0.2 * PI, 0.8 * PI, 10, Draw.INK, 3)
	# Windscreen and wiper.
	var ws := Rect2(bc + Vector2(150, -120), Vector2(100, 110))
	Draw.rounded_rect(self, ws, 18, Color("d6f2ff"))
	var wa := -0.3 - sin(_wiper * PI * 4) * 1.0 * _wiper
	var wp := ws.position + Vector2(50, 104)
	draw_line(wp, wp + Vector2(cos(-PI / 2 + wa), sin(-PI / 2 + wa)) * 90, Draw.INK, 6)
	# Horn / headlight.
	var hp := _horn_pos()
	draw_circle(hp, 22 + 8 * _horn, Color("fff3b0"))
	if _horn > 0:
		for k in 3:
			draw_arc(hp, 40 + k * 18 + (1 - _horn) * 20, -0.5, 0.5, 8, Color(1, 0.3, 0.2, _horn), 5)
	# Wheels.
	for wx in [-170, 150]:
		var wc := bc + Vector2(wx, 120)
		draw_circle(wc, 58, Draw.INK)
		draw_circle(wc, 26, Color("d0d4dc"))
		for k in 5:
			var a := _wheel_spin + TAU * k / 5
			draw_line(wc, wc + Vector2(cos(a), sin(a)) * 48, Color("d0d4dc"), 6)
	Draw.text(self, Vector2(W / 2 + 70, H - 270), "Tap the wheels, horn and wipers!", 28, Draw.INK)


func _draw_farm() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("9fe0ff"))
	draw_circle(Vector2(W - 120, 240), 64, Color("fff07a"))
	draw_colored_polygon(_hill(H * 0.38, 70), Color("8fe06a"))
	# Barn.
	var bc := Vector2(150, H * 0.44)
	draw_colored_polygon(PackedVector2Array([bc + Vector2(-110, -40), bc + Vector2(0, -140), bc + Vector2(110, -40), bc + Vector2(110, 120), bc + Vector2(-110, 120)]), Draw.RED)
	draw_rect(Rect2(bc + Vector2(-45, 30), Vector2(90, 90)), Color.WHITE)
	draw_line(bc + Vector2(-45, 30), bc + Vector2(45, 120), Draw.RED, 8)
	draw_line(bc + Vector2(45, 30), bc + Vector2(-45, 120), Draw.RED, 8)
	draw_rect(Rect2(0, H * 0.5, W, H * 0.5), Color("6fcf4a"))
	for i in 9:
		var x := 20.0 + i * 90
		draw_rect(Rect2(x, H * 0.5 - 70, 16, 80), Color("c98b5c"))
	draw_rect(Rect2(0, H * 0.5 - 56, W, 12), Color("c98b5c"))
	draw_rect(Rect2(0, H * 0.5 - 26, W, 12), Color("c98b5c"))
	var ap := _animal_pos() + Vector2(0, -abs(sin(_animal_bounce * PI)) * 60)
	match _verse_animal():
		"cow":
			_cow(ap)
		"duck":
			_duck(ap)
		_:
			_pig(ap)
	Draw.text(self, Vector2(W / 2 + 70, H - 270), "Tap the animal!", 32, Draw.INK)


func _face(c: Vector2, s: float) -> void:
	draw_circle(c + Vector2(-26, -10) * s, 10 * s, Draw.INK)
	draw_circle(c + Vector2(26, -10) * s, 10 * s, Draw.INK)
	draw_circle(c + Vector2(-23, -14) * s, 3.5 * s, Color.WHITE)
	draw_circle(c + Vector2(29, -14) * s, 3.5 * s, Color.WHITE)
	Draw.ellipse(self, c + Vector2(-48, 12) * s, 12 * s, 7 * s, Draw.CHEEK)
	Draw.ellipse(self, c + Vector2(48, 12) * s, 12 * s, 7 * s, Draw.CHEEK)


func _cow(p: Vector2) -> void:
	Draw.ellipse(self, p + Vector2(0, 60), 150, 95, Color.WHITE)
	Draw.ellipse(self, p + Vector2(-60, 40), 40, 30, Draw.INK)
	Draw.ellipse(self, p + Vector2(70, 80), 35, 25, Draw.INK)
	for x in [-90, -40, 40, 90]:
		draw_rect(Rect2(p + Vector2(x - 14, 130), Vector2(28, 50)), Color.WHITE)
	var h := p + Vector2(0, -80)
	Draw.ellipse(self, h + Vector2(-90, -30), 34, 16, Color.WHITE, -0.4)
	Draw.ellipse(self, h + Vector2(90, -30), 34, 16, Color.WHITE, 0.4)
	Draw.ellipse(self, h + Vector2(-50, -80), 10, 26, Draw.YELLOW, -0.3)
	Draw.ellipse(self, h + Vector2(50, -80), 10, 26, Draw.YELLOW, 0.3)
	Draw.ellipse(self, h, 90, 85, Color.WHITE)
	Draw.ellipse(self, h + Vector2(0, 45), 70, 40, Color("ffb3c8"))
	draw_circle(h + Vector2(-24, 45), 8, Color("d06a8a"))
	draw_circle(h + Vector2(24, 45), 8, Color("d06a8a"))
	_face(h + Vector2(0, -10), 1.0)


func _duck(p: Vector2) -> void:
	Draw.ellipse(self, p + Vector2(0, 80), 140, 90, Draw.YELLOW)
	Draw.ellipse(self, p + Vector2(40, 70), 70, 40, Color("ffe27a"), -0.3)
	var h := p + Vector2(-40, -60)
	draw_circle(h, 90, Draw.YELLOW)
	Draw.ellipse(self, h + Vector2(0, 40), 56, 24, Draw.ORANGE)
	Draw.ellipse(self, h + Vector2(0, 52), 40, 14, Color("e06a1a"))
	_face(h + Vector2(0, -16), 0.95)


func _pig(p: Vector2) -> void:
	var pink := Color("ffa8c8")
	Draw.ellipse(self, p + Vector2(0, 70), 150, 100, pink)
	for x in [-90, -40, 40, 90]:
		draw_rect(Rect2(p + Vector2(x - 16, 140), Vector2(32, 44)), pink.darkened(0.1))
	var h := p + Vector2(0, -60)
	draw_colored_polygon(PackedVector2Array([h + Vector2(-80, -40), h + Vector2(-60, -110), h + Vector2(-20, -70)]), pink.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([h + Vector2(80, -40), h + Vector2(60, -110), h + Vector2(20, -70)]), pink.darkened(0.1))
	Draw.ellipse(self, h, 100, 88, pink)
	Draw.ellipse(self, h + Vector2(0, 36), 40, 28, Color("ff7aa8"))
	draw_circle(h + Vector2(-13, 36), 7, Color("c0406a"))
	draw_circle(h + Vector2(13, 36), 7, Color("c0406a"))
	_face(h + Vector2(0, -16), 1.0)


func _hill(y: float, rise: float) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(0, H), Vector2(0, y + rise)])
	for i in 21:
		pts.append(Vector2(W * i / 20.0, y + rise - sin(PI * i / 20.0) * rise))
	pts.append(Vector2(W, H))
	return pts
