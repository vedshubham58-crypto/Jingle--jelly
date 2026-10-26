extends Screen
## Pick a game: a grid of big picture cards.

const GAMES := [
	{"id": "bubbles", "title": "Bubble Pop", "color": Color("2fbf71")},
	{"id": "feed", "title": "Feed Jelly", "color": Color("ff7eb6")},
	{"id": "shapes", "title": "Shapes", "color": Color("8b5cff")},
	{"id": "balloons", "title": "Balloon ABC", "color": Color("ff8a3d")},
	{"id": "bath", "title": "Bath Time", "color": Color("3fb6ff")},
]


func _ready() -> void:
	super._ready()
	Voice.say("Let's play a game!")


func layout() -> void:
	add_back(func() -> void: main.show_screen("home"))
	var top := 190.0
	var gap := 24.0
	var rows := int(ceil(GAMES.size() / 2.0))
	var cw := (W - 60 - gap) / 2
	var ch: float = min(330.0, (H - top - 40 - gap * (rows - 1)) / rows)
	for i in GAMES.size():
		var id: String = GAMES[i].id
		var x := 30 + (i % 2) * (cw + gap)
		if i == GAMES.size() - 1 and GAMES.size() % 2 == 1:
			x = (W - cw) / 2
		add_button(id, Rect2(x, top + (i / 2) * (ch + gap), cw, ch), func() -> void: main.show_screen(id))


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("a8e6ff"))
	for i in 9:
		var x := fmod(i * 97.0 + t * 20.0, W + 100) - 50
		Draw.star(self, Vector2(x, 160 + (i % 3) * 330 + sin(t + i) * 20), 22, Color(1, 1, 1, 0.5), t * 0.5 + i)
	Draw.text(self, Vector2(W / 2 + 30, 92), "Let's play!", 76, Color.WHITE, Color("1f8fd6"), 20)
	draw_back()
	for g in GAMES:
		var b := button(g.id)
		if b.is_empty():
			continue
		var r: Rect2 = b.rect
		Draw.button_face(self, r, 34, Color.WHITE, b.down)
		if b.down:
			r.position.y += 10
		var text_h := 70.0
		var pic := Rect2(r.position + Vector2(12, 12), Vector2(r.size.x - 24, r.size.y - 24 - text_h))
		Draw.rounded_rect(self, pic, 26, g.color)
		_picture(g.id, pic)
		Draw.text(self, Vector2(r.get_center().x, pic.end.y + text_h / 2 + 6), g.title, 36, Draw.INK)


func _picture(id: String, r: Rect2) -> void:
	var c := r.get_center()
	var k: float = min(r.size.x, r.size.y) / 200.0
	draw_circle(c, 80 * k, Color(1, 1, 1, 0.22))
	match id:
		"bubbles":
			Draw.bubble(self, c + Vector2(-30, 14) * k, 46 * k, Draw.RED)
			Draw.bubble(self, c + Vector2(40, -24) * k, 36 * k, Draw.YELLOW)
			Draw.bubble(self, c + Vector2(30, 48) * k, 24 * k, Draw.BLUE)
		"feed":
			Draw.fruit(self, "banana", c + Vector2(-48, 20) * k, 38 * k)
			Draw.fruit(self, "apple", c + Vector2(10, -20) * k, 42 * k)
			Draw.fruit(self, "strawberry", c + Vector2(58, 34) * k, 30 * k)
		"shapes":
			Draw.shape(self, "circle", c + Vector2(-48, -26) * k, 34 * k, Draw.RED)
			Draw.shape(self, "star", c + Vector2(44, -26) * k, 36 * k, Draw.YELLOW)
			Draw.shape(self, "triangle", c + Vector2(-40, 44) * k, 34 * k, Draw.GREEN)
			Draw.shape(self, "heart", c + Vector2(46, 42) * k, 32 * k, Draw.PINK)
		"balloons":
			var bob := sin(t * 2) * 6 * k
			for j in 3:
				var bc := c + Vector2(-56 + j * 56, -20 - (j % 2) * 18) * k + Vector2(0, bob * (1 if j % 2 == 0 else -1))
				Draw.balloon(self, bc, 30 * k, [Draw.RED, Draw.BLUE, Draw.YELLOW][j])
				Draw.text(self, bc + Vector2(0, -2 * k), ["A", "B", "C"][j], int(34 * k), Color.WHITE, Color(0, 0, 0, 0.25), 6)
		"bath":
			Draw.rounded_rect(self, Rect2(c + Vector2(-70, 0) * k, Vector2(140, 56) * k), 28 * k, Color.WHITE)
			draw_rect(Rect2(c + Vector2(-78, -6) * k, Vector2(156, 14) * k), Color.WHITE)
			for j in 4:
				Draw.bubble(self, c + Vector2(-48 + 32 * j, -26 - 12 * (j % 2)) * k, 18 * k, Color("d8f3ff"))
			Draw.ellipse(self, c + Vector2(40, -50) * k, 22 * k, 16 * k, Draw.YELLOW)
			draw_circle(c + Vector2(58, -62) * k, 12 * k, Draw.YELLOW)
			draw_circle(c + Vector2(61, -64) * k, 3 * k, Draw.INK)
