extends Screen
## Pick a song: a grid of big picture cards.

const SONGS := [
	{"id": "twinkle", "title": "Twinkle Twinkle", "color": Color("5b6cff")},
	{"id": "bus", "title": "Wheels on the Bus", "color": Color("ff9a2e")},
	{"id": "farm", "title": "Old MacDonald", "color": Color("2fbf71")},
	{"id": "baa", "title": "Baa Baa Black Sheep", "color": Color("8fd16a")},
	{"id": "boat", "title": "Row Your Boat", "color": Color("3aa8ff")},
	{"id": "spider", "title": "Itsy Bitsy Spider", "color": Color("9b6bff")},
	{"id": "mary", "title": "Mary's Little Lamb", "color": Color("ff7eb6")},
	{"id": "body", "title": "Head and Shoulders", "color": Color("ffb347")},
]


func _ready() -> void:
	super._ready()
	Voice.say("Pick a song!")


func layout() -> void:
	add_back(func() -> void: main.show_screen("home"))
	var top := 190.0
	var gap := 24.0
	var cols := 2
	var rows := int(ceil(SONGS.size() / float(cols)))
	var cw := (W - 60 - gap) / cols
	var ch: float = min(330.0, (H - top - 40 - gap * (rows - 1)) / rows)
	for i in SONGS.size():
		var id: String = SONGS[i].id
		var r := Rect2(30 + (i % cols) * (cw + gap), top + (i / cols) * (ch + gap), cw, ch)
		add_button(id, r, func() -> void: main.show_screen("player", id))


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
		Draw.button_face(self, r, 34, Color.WHITE, b.down)
		if b.down:
			r.position.y += 10
		var text_h := 84.0
		var pic := Rect2(r.position + Vector2(12, 12), Vector2(r.size.x - 24, r.size.y - 24 - text_h))
		Draw.rounded_rect(self, pic, 26, s.color)
		_picture(s.id, pic, s.color)
		var words: PackedStringArray = s.title.split(" ")
		var line1: String = s.title
		var line2 := ""
		var size := 34
		if Draw.text_width(line1, size) > r.size.x - 30 and words.size() > 1:
			var half := int(ceil(words.size() / 2.0))
			line1 = " ".join(words.slice(0, half))
			line2 = " ".join(words.slice(half))
		var ty := pic.end.y + text_h / 2 + 6
		if line2 == "":
			Draw.text(self, Vector2(r.get_center().x, ty), line1, size, Draw.INK)
		else:
			Draw.text(self, Vector2(r.get_center().x, ty - 19), line1, size - 2, Draw.INK)
			Draw.text(self, Vector2(r.get_center().x, ty + 19), line2, size - 2, Draw.INK)
		var pc := pic.end - Vector2(34, 34)
		draw_circle(pc, 24, Color(1, 1, 1, 0.9))
		draw_colored_polygon(PackedVector2Array([pc + Vector2(-7, -12), pc + Vector2(-7, 12), pc + Vector2(13, 0)]), s.color)


func _picture(id: String, r: Rect2, col: Color) -> void:
	var c := r.get_center()
	var k: float = min(r.size.x, r.size.y) / 200.0
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
			Draw.rounded_rect(self, Rect2(r.position + Vector2(0, r.size.y * 0.7), Vector2(r.size.x, r.size.y * 0.3)), 26, Color("1f9e55"))
			var bc := c + Vector2(0, 10) * k
			draw_colored_polygon(PackedVector2Array([bc + Vector2(-60, -10) * k, bc + Vector2(0, -60) * k, bc + Vector2(60, -10) * k, bc + Vector2(60, 50) * k, bc + Vector2(-60, 50) * k]), Draw.RED)
			draw_rect(Rect2(bc + Vector2(-20, 10) * k, Vector2(40, 40) * k), Color.WHITE)
			draw_line(bc + Vector2(-20, 10) * k, bc + Vector2(20, 50) * k, Draw.RED, 5 * k)
			draw_line(bc + Vector2(20, 10) * k, bc + Vector2(-20, 50) * k, Draw.RED, 5 * k)
		"baa":
			Draw.rounded_rect(self, Rect2(r.position + Vector2(0, r.size.y * 0.72), Vector2(r.size.x, r.size.y * 0.28)), 26, Color("5fb84a"))
			var sc := c + Vector2(10, 10) * k
			for i in 7:
				var a := TAU * i / 7
				draw_circle(sc + Vector2(cos(a) * 46, sin(a) * 30) * k, 30 * k, Color("3a3f55"))
			draw_circle(sc, 44 * k, Color("3a3f55"))
			for lx in [-30, 30]:
				draw_rect(Rect2(sc + Vector2(lx - 5, 30) * k, Vector2(10, 28) * k), Draw.INK)
			var hc := sc + Vector2(-62, -12) * k
			Draw.ellipse(self, hc, 26 * k, 22 * k, Draw.INK)
			draw_circle(hc + Vector2(-8, -4) * k, 6 * k, Color.WHITE)
			draw_circle(hc + Vector2(8, -4) * k, 6 * k, Color.WHITE)
			for i in 3:
				var bc := c + Vector2(-60 + i * 30, -62) * k
				Draw.rounded_rect(self, Rect2(bc - Vector2(12, 14) * k, Vector2(24, 28) * k), 6 * k, Color("e8c48a"))
		"boat":
			Draw.rounded_rect(self, Rect2(r.position + Vector2(0, r.size.y * 0.55), Vector2(r.size.x, r.size.y * 0.45)), 26, Color("1f7fd6"))
			var bob := sin(t * 2.5) * 5 * k
			var bc := c + Vector2(0, 10) * k + Vector2(0, bob)
			draw_colored_polygon(PackedVector2Array([bc + Vector2(-80, -10) * k, bc + Vector2(80, -10) * k, bc + Vector2(55, 25) * k, bc + Vector2(-55, 25) * k]), Draw.RED)
			draw_circle(bc + Vector2(-25, -30) * k, 22 * k, Draw.GREEN)
			draw_circle(bc + Vector2(25, -30) * k, 22 * k, Draw.PINK)
			draw_line(bc + Vector2(-60, -20) * k, bc + Vector2(-95, 35) * k, Color("8a5a2b"), 6 * k)
			for i in 3:
				draw_arc(c + Vector2(-70 + i * 70, 70) * k, 18 * k, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.6), 4 * k)
		"spider":
			draw_rect(Rect2(c + Vector2(40, -90) * k, Vector2(22, 180) * k), Color("8d97a8"))
			var sy := c.y + sin(t * 1.5) * 30 * k
			var sp := Vector2(c.x - 10 * k, sy)
			draw_line(Vector2(sp.x, r.position.y + 8), sp, Color(1, 1, 1, 0.7), 2 * k)
			for side in [-1, 1]:
				for j in 4:
					var a := -0.6 + j * 0.4
					var knee := sp + Vector2(side * 34, -12 + j * 8).rotated(side * a * 0.3) * k
					draw_polyline(PackedVector2Array([sp, knee, knee + Vector2(side * 12, 18) * k]), Draw.INK, 5 * k)
			draw_circle(sp, 28 * k, Color("3b2a6b"))
			draw_circle(sp + Vector2(-10, -4) * k, 8 * k, Color.WHITE)
			draw_circle(sp + Vector2(10, -4) * k, 8 * k, Color.WHITE)
			draw_circle(sp + Vector2(-9, -3) * k, 4 * k, Draw.INK)
			draw_circle(sp + Vector2(11, -3) * k, 4 * k, Draw.INK)
		"mary":
			Draw.rounded_rect(self, Rect2(r.position + Vector2(0, r.size.y * 0.72), Vector2(r.size.x, r.size.y * 0.28)), 26, Color("8fd16a"))
			var lc := c + Vector2(0, 15) * k
			for i in 7:
				var a := TAU * i / 7
				draw_circle(lc + Vector2(cos(a) * 46, sin(a) * 30) * k, 30 * k, Color.WHITE)
			draw_circle(lc, 44 * k, Color.WHITE)
			for lx in [-30, 30]:
				draw_rect(Rect2(lc + Vector2(lx - 5, 30) * k, Vector2(10, 28) * k), Draw.INK)
			var hc := lc + Vector2(-62, -12) * k
			Draw.ellipse(self, hc, 26 * k, 22 * k, Color("ffe0cc"))
			draw_circle(hc + Vector2(-8, -4) * k, 5 * k, Draw.INK)
			draw_circle(hc + Vector2(8, -4) * k, 5 * k, Draw.INK)
			Draw.ellipse(self, hc + Vector2(0, 10) * k, 6 * k, 4 * k, Draw.CHEEK)
			for i in 3:
				Draw.star(self, c + Vector2(-60 + i * 60, -70) * k, 12 * k, Color.WHITE)
		"body":
			var fc := c + Vector2(0, -20) * k
			draw_circle(fc, 50 * k, Draw.SKIN)
			draw_arc(fc, 50 * k, PI * 1.05, PI * 1.95, 20, Color("6b3e1f"), 22 * k)
			draw_circle(fc + Vector2(-17, -2) * k, 6 * k, Draw.INK)
			draw_circle(fc + Vector2(17, -2) * k, 6 * k, Draw.INK)
			draw_arc(fc + Vector2(0, 14) * k, 14 * k, 0.15 * PI, 0.85 * PI, 10, Draw.INK, 4 * k)
			Draw.ellipse(self, fc + Vector2(-30, 12) * k, 9 * k, 6 * k, Draw.CHEEK)
			Draw.ellipse(self, fc + Vector2(30, 12) * k, 9 * k, 6 * k, Draw.CHEEK)
			var wave := sin(t * 4) * 0.4
			for side in [-1, 1]:
				var hand := fc + Vector2(side * 72, -40 + side * wave * 30) * k
				draw_line(fc + Vector2(side * 40, 55) * k, hand, Draw.SKIN, 12 * k)
				draw_circle(hand, 12 * k, Draw.SKIN)
			Draw.rounded_rect(self, Rect2(fc + Vector2(-42, 45) * k, Vector2(84, 50) * k), 18 * k, Draw.BLUE)
