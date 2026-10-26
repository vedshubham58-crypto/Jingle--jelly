extends Screen
## Pick a song: three big picture cards.

const SONGS := [
	{"id": "twinkle", "title": "Twinkle Twinkle", "color": Color("5b6cff")},
	{"id": "bus", "title": "Wheels on the Bus", "color": Color("ff9a2e")},
	{"id": "farm", "title": "Old MacDonald", "color": Color("2fbf71")},
]


func _ready() -> void:
	super._ready()
	Voice.say("Pick a song!")


func layout() -> void:
	add_back(func() -> void: main.show_screen("home"))
	var top := 220.0
	var gap := 30.0
	var ch: float = min(250.0, (H - top - 80 - gap * 2) / 3.0)
	for i in SONGS.size():
		var id: String = SONGS[i].id
		add_button(id, Rect2(40, top + i * (ch + gap), W - 80, ch), func() -> void: main.show_screen("player", id))


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("ffb3d9"))
	for i in 9:
		var x := fmod(i * 97.0 + t * 20.0, W + 100) - 50
		Draw.note(self, Vector2(x, 160 + (i % 3) * 330 + sin(t + i) * 20), 50, Color(1, 1, 1, 0.35), i % 2 == 0)
	Draw.text(self, Vector2(W / 2 + 30, 92), "Sing along!", 76, Color.WHITE, Draw.PINK_DARK, 20)
	draw_back()
	for s in SONGS:
		var b := button(s.id)
		if b.is_empty():
			continue
		var r: Rect2 = b.rect
		Draw.button_face(self, r, 40, Color.WHITE, b.down)
		if b.down:
			r.position.y += 10
		var pic := Rect2(r.position + Vector2(18, 18), Vector2(r.size.y - 36, r.size.y - 36))
		Draw.rounded_rect(self, pic, 30, s.color)
		_picture(s.id, pic, s.color)
		var tx := pic.end.x + (r.end.x - pic.end.x - 90) / 2
		var words: PackedStringArray = s.title.split(" ")
		var line1: String = s.title
		var line2 := ""
		if Draw.text_width(line1, 44) > r.end.x - pic.end.x - 110 and words.size() > 1:
			var half := int(ceil(words.size() / 2.0))
			line1 = " ".join(words.slice(0, half))
			line2 = " ".join(words.slice(half))
		if line2 == "":
			Draw.text(self, Vector2(tx, r.get_center().y), line1, 44, Draw.INK)
		else:
			Draw.text(self, Vector2(tx, r.get_center().y - 26), line1, 44, Draw.INK)
			Draw.text(self, Vector2(tx, r.get_center().y + 26), line2, 44, Draw.INK)
		var pc := Vector2(r.end.x - 56, r.get_center().y)
		draw_circle(pc, 30, s.color)
		draw_colored_polygon(PackedVector2Array([pc + Vector2(-9, -15), pc + Vector2(-9, 15), pc + Vector2(16, 0)]), Color.WHITE)


func _picture(id: String, r: Rect2, col: Color) -> void:
	var c := r.get_center()
	var k := r.size.x / 200.0
	match id:
		"twinkle":
			draw_circle(c + Vector2(48, -48) * k, 26 * k, Color("fff3b0"))
			draw_circle(c + Vector2(60, -56) * k, 22 * k, col)
			Draw.star(self, c + Vector2(-10, 10) * k, 62 * k, Draw.YELLOW, sin(t * 2) * 0.1)
			draw_circle(c + Vector2(-26, 8) * k, 6 * k, Draw.INK)
			draw_circle(c + Vector2(6, 8) * k, 6 * k, Draw.INK)
			draw_arc(c + Vector2(-10, 18) * k, 12 * k, 0.2 * PI, 0.8 * PI, 10, Draw.INK, 4 * k)
			for i in 4:
				Draw.star(self, c + Vector2(-70 + 40 * i, -70 + 120 * (i % 2)) * k, 9 * k, Color.WHITE)
		"bus":
			var b := Rect2(c + Vector2(-80, -45) * k, Vector2(160, 80) * k)
			Draw.rounded_rect(self, b, 18 * k, Draw.YELLOW)
			for i in 3:
				Draw.rounded_rect(self, Rect2(b.position + Vector2(14 + 46 * i, 12) * k, Vector2(36, 28) * k), 6 * k, Color("bfe9ff"))
			var spin := t * 4
			for wx in [-45, 45]:
				var wc := c + Vector2(wx, 38) * k
				draw_circle(wc, 20 * k, Draw.INK)
				draw_circle(wc, 8 * k, Color("cccccc"))
				draw_line(wc, wc + Vector2(cos(spin), sin(spin)) * 16 * k, Color("cccccc"), 3 * k)
		"farm":
			draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.7), Vector2(r.size.x, r.size.y * 0.3)), Color("1f9e55"))
			var bc := c + Vector2(0, 10) * k
			draw_colored_polygon(PackedVector2Array([bc + Vector2(-60, -10) * k, bc + Vector2(0, -60) * k, bc + Vector2(60, -10) * k, bc + Vector2(60, 50) * k, bc + Vector2(-60, 50) * k]), Draw.RED)
			draw_rect(Rect2(bc + Vector2(-20, 10) * k, Vector2(40, 40) * k), Color.WHITE)
			draw_line(bc + Vector2(-20, 10) * k, bc + Vector2(20, 50) * k, Draw.RED, 5 * k)
			draw_line(bc + Vector2(20, 10) * k, bc + Vector2(-20, 50) * k, Draw.RED, 5 * k)
