extends Screen
## Home: Jelly and friends dance to the music; three big picture buttons.

const BPM := 100.0
const HELLO := ["Hi! I'm Jelly!", "Let's play!", "Hee hee! That tickles!", "Want to sing a song?"]

var jelly: Jelly
var friends: Array[Jelly] = []
var _notes: Array[Dictionary] = []
var _hello := 0


func _ready() -> void:
	jelly = Jelly.new()
	add_child(jelly)
	for col in [Draw.GREEN, Draw.BLUE]:
		var f := Jelly.new()
		f.color = col
		f.size = 150
		add_child(f)
		friends.append(f)
	move_child(friends[0], 0)
	move_child(friends[1], 0)
	super._ready()
	Voice.say("Hi! Let's play with Jelly!")


func layout() -> void:
	var base := H - 360
	jelly.size = min(330.0, W * 0.46)
	jelly.position = Vector2(W / 2, base)
	friends[0].position = Vector2(W / 2 - 220, base + 22)
	friends[1].position = Vector2(W / 2 + 220, base + 22)
	var bw := (W - 80) / 3.0
	var bh := 230.0
	var y := H - bh - 70
	add_button("songs", Rect2(20, y, bw - 10, bh), func() -> void: main.show_screen("songs"))
	add_button("bath", Rect2(20 + bw + 10, y, bw - 10, bh), func() -> void: main.show_screen("bath"))
	add_button("bubbles", Rect2(20 + 2 * (bw + 10), y, bw - 10, bh), func() -> void: main.show_screen("bubbles"))
	add_button("parent", Rect2(W - 112, 34, 88, 88), func() -> void: main.show_screen("gate"))


func tick(delta: float) -> void:
	jelly.bob = Screen.hop(t, BPM, 26)
	friends[0].bob = Screen.hop(t + 0.3, BPM, 18)
	friends[1].bob = Screen.hop(t + 0.15, BPM, 18)
	jelly.look = Vector2(sin(t * 0.7) * 0.6, 0.1)
	if fmod(t * BPM / 60.0, 1.0) < delta * BPM / 60.0:
		jelly.poke(0.12)
		for f in friends:
			f.poke(0.1)
		if randf() < 0.5:
			_notes.append({"p": Vector2(randf_range(60, W - 60), H * 0.5), "v": randf_range(60, 110), "c": [Draw.PINK, Draw.BLUE, Draw.GREEN, Draw.PURPLE].pick_random(), "d": randf() < 0.5, "a": 1.0})
	for n in _notes:
		n.p.y -= n.v * delta
		n.p.x += sin(t * 3 + n.v) * 0.6
		n.a -= delta * 0.22
	_notes = _notes.filter(func(n: Dictionary) -> bool: return n.a > 0)


func press(p: Vector2) -> void:
	for j in [jelly] + friends:
		if p.distance_to(j.position + Vector2(0, -j.size * 0.45)) < j.size * 0.55:
			j.poke(0.6)
			j.mood = "giggle"
			Audio.sfx("boing", randf_range(0.9, 1.2))
			get_tree().create_timer(0.9).timeout.connect(func() -> void:
				if is_instance_valid(j):
					j.mood = "smile")
			if j == jelly:
				Voice.say(HELLO[_hello % HELLO.size()])
				_hello += 1
			return


func _draw() -> void:
	# Sunny background with slowly turning rays.
	draw_rect(Rect2(0, 0, W, H), Draw.YELLOW)
	var c := Vector2(W / 2, H * 0.4)
	for i in 16:
		var a := t * 0.08 + TAU * i / 16
		var pts := PackedVector2Array([c, c + Vector2(cos(a - 0.1), sin(a - 0.1)) * H, c + Vector2(cos(a + 0.1), sin(a + 0.1)) * H])
		draw_colored_polygon(pts, Color(1, 1, 1, 0.13))
	draw_circle(c, W * 0.42, Color(1, 1, 1, 0.18))
	# Grass hill the friends stand on.
	draw_colored_polygon(_hill(H - 420), Color("8fe06a"))
	draw_colored_polygon(_hill(H - 385), Color("6fcf4a"))
	for i in 7:
		var fx := 50.0 + (W - 100) * i / 6.0
		var fy := H - 330.0 + (i % 2) * 22.0
		_flower(Vector2(fx, fy), [Draw.PINK, Color.WHITE, Draw.PURPLE, Draw.ORANGE][i % 4])
	for n in _notes:
		Draw.note(self, n.p, 46, Color(n.c, n.a), n.d)
	# Title.
	var ty := H * 0.17
	Draw.text(self, Vector2(W / 2 + 4, ty + 6), "Jingle Jelly", 104, Color(0, 0, 0, 0.12))
	Draw.text(self, Vector2(W / 2, ty), "Jingle Jelly", 104, Draw.PINK, Color.WHITE, 26)
	Draw.text(self, Vector2(W / 2, ty + 84), "Sing  •  Play  •  Learn", 34, Draw.INK)
	# Stars collected.
	Draw.rounded_rect(self, Rect2(24, 44, 170, 70), 35, Color(1, 1, 1, 0.9))
	Draw.star(self, Vector2(64, 79), 26, Draw.ORANGE)
	Draw.text(self, Vector2(132, 78), str(Save.stars), 40, Draw.INK)
	# Grown-ups button (a little lock).
	var pb := button("parent")
	if not pb.is_empty():
		var r: Rect2 = pb.rect
		Draw.button_face(self, r, 44, Color.WHITE, pb.down)
		var lc := r.get_center() + Vector2(0, 10 if pb.down else 0)
		draw_arc(lc + Vector2(0, -6), 14, PI, TAU, 16, Color("9aa3b5"), 7, true)
		Draw.rounded_rect(self, Rect2(lc + Vector2(-20, -6), Vector2(40, 30)), 7, Color("9aa3b5"))
	_draw_card("songs", "Songs", Draw.PINK)
	_draw_card("bath", "Bath", Draw.BLUE)
	_draw_card("bubbles", "Bubbles", Draw.GREEN)


func _flower(p: Vector2, col: Color) -> void:
	draw_line(p, p + Vector2(0, 24), Color("3f9e35"), 4)
	for k in 5:
		var a := TAU * k / 5 + t * 0.5
		draw_circle(p + Vector2(cos(a), sin(a)) * 9, 8, col)
	draw_circle(p, 7, Draw.YELLOW)


func _hill(y: float) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(0, H), Vector2(0, y + 40)])
	for i in 21:
		var x := W * i / 20.0
		pts.append(Vector2(x, y + 40 - sin(PI * i / 20.0) * 60))
	pts.append(Vector2(W, H))
	return pts


func _draw_card(id: String, label: String, col: Color) -> void:
	var b := button(id)
	if b.is_empty():
		return
	var r: Rect2 = b.rect
	var wig := sin(t * 3 + r.position.x) * 3.0
	r.position.y += wig
	Draw.button_face(self, r, 34, col, b.down)
	if b.down:
		r.position.y += 10
	var ic := r.get_center() + Vector2(0, -28)
	match id:
		"songs":
			draw_circle(ic, 62, Color(1, 1, 1, 0.25))
			Draw.note(self, ic + Vector2(-26, 26), 70, Color.WHITE, true)
		"bath":
			draw_circle(ic, 62, Color(1, 1, 1, 0.25))
			Draw.rounded_rect(self, Rect2(ic + Vector2(-52, -2), Vector2(104, 44)), 22, Color.WHITE)
			draw_rect(Rect2(ic + Vector2(-58, -6), Vector2(116, 12)), Color.WHITE)
			for k in 3:
				Draw.bubble(self, ic + Vector2(-30 + 28 * k, -22 - 10 * (k % 2)), 15, Color("d8f3ff"))
		"bubbles":
			draw_circle(ic, 62, Color(1, 1, 1, 0.25))
			Draw.bubble(self, ic + Vector2(-18, 10), 30, Draw.RED)
			Draw.bubble(self, ic + Vector2(26, -14), 24, Draw.YELLOW)
			Draw.bubble(self, ic + Vector2(16, 32), 16, Draw.BLUE)
	Draw.text(self, Vector2(r.get_center().x, r.end.y - 38), label, 40, Color.WHITE, col.darkened(0.3), 10)
