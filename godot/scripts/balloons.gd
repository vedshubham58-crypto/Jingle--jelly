extends Screen
## Balloon ABC: "Find the letter B!" Pop balloons with that letter. Teaches
## letters and their first words.

const ROUNDS := [["A", "Apple"], ["B", "Ball"], ["C", "Cat"], ["D", "Duck"], ["E", "Egg"]]
const LETTERS := ["A", "B", "C", "D", "E", "F", "G", "H"]
const COLORS := [Color("ff4a3d"), Color("3b8bff"), Color("2fbf71"), Color("ffc21a"), Color("a05cff"), Color("ff7eb6"), Color("ff8a3d")]
const NEED := 2

var round_i := 0
var popped := 0
var balloons: Array[Dictionary] = []
var pops: Array[Dictionary] = []
var jelly: Jelly
var _spawn := 0.0
var _between := 0.0
var _finished := false


func _ready() -> void:
	jelly = Jelly.new()
	jelly.color = Draw.BLUE
	add_child(jelly)
	super._ready()
	_announce()


func layout() -> void:
	add_back(func() -> void: main.show_screen("games"))
	jelly.size = 170
	jelly.position = Vector2(W - 120, H - 40)


func target() -> String:
	return ROUNDS[min(round_i, ROUNDS.size() - 1)][0]


func word() -> String:
	return ROUNDS[min(round_i, ROUNDS.size() - 1)][1]


func _announce() -> void:
	Voice.say("Find the letter %s! %s is for %s!" % [target(), target(), word()])


func tick(delta: float) -> void:
	_spawn -= delta
	if _spawn <= 0 and balloons.size() < 8 and not _finished:
		_spawn = randf_range(0.5, 0.85)
		var is_target := randf() < 0.42
		var letter: String = target() if is_target else LETTERS.filter(func(l: String) -> bool: return l != target()).pick_random()
		var r := randf_range(62, 80)
		balloons.append({"p": Vector2(randf_range(r + 10, W - r - 10), H + r * 1.2), "r": r, "letter": letter, "col": COLORS.pick_random(), "v": randf_range(80, 140), "ph": randf() * TAU, "shake": 0.0})
	for b in balloons:
		b.p.y -= b.v * delta
		b.p.x += sin(t * 1.3 + b.ph) * 0.7
		b.shake = max(0.0, b.shake - delta * 2)
	balloons = balloons.filter(func(b: Dictionary) -> bool: return b.p.y > -b.r * 2.5)
	for p in pops:
		p.t += delta
	pops = pops.filter(func(p: Dictionary) -> bool: return p.t < 0.9)
	if _between > 0:
		_between -= delta
		if _between <= 0:
			round_i += 1
			popped = 0
			if round_i >= ROUNDS.size():
				_finished = true
				main.celebrate("games")
			else:
				_announce()
	jelly.look = Vector2(-0.6, -0.6)


func press(p: Vector2) -> void:
	if _between > 0 or _finished:
		return
	for i in range(balloons.size() - 1, -1, -1):
		var b := balloons[i]
		if p.distance_to(b.p) < b.r + 16:
			if b.letter == target():
				balloons.remove_at(i)
				popped += 1
				Audio.sfx("pop", 0.8 + popped * 0.1)
				pops.append({"p": b.p, "c": b.col, "letter": b.letter, "t": 0.0, "r": b.r})
				Voice.say(b.letter)
				jelly.poke(0.4)
				jelly.mouth_open = 1.0
				if popped >= NEED:
					_between = 2.0
					Audio.sfx("chime")
					Voice.say("%s is for %s!" % [target(), word()])
					jelly.mood = "giggle"
					get_tree().create_timer(1.6).timeout.connect(func() -> void:
						if is_instance_valid(jelly):
							jelly.mood = "smile")
			else:
				b.shake = 1.0
				Audio.sfx("wrong")
				Voice.say("That's %s!" % b.letter)
			return


func _draw() -> void:
	Draw.gradient_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]), Color("ffb36b"), Color("ffe9a8"))
	draw_circle(Vector2(W * 0.2, H * 0.3), 90, Color(1, 1, 1, 0.35))
	for i in 3:
		var cx := fmod(80.0 + i * 280 + t * 10, W + 200) - 100
		for k in 3:
			draw_circle(Vector2(cx + k * 44, 360 + i * 240 - (k % 2) * 22), 38, Color(1, 1, 1, 0.7))
	draw_colored_polygon(PackedVector2Array([Vector2(0, H), Vector2(0, H - 140), Vector2(W * 0.3, H - 190), Vector2(W * 0.7, H - 150), Vector2(W, H - 200), Vector2(W, H)]), Color("8fd16a"))
	for b in balloons:
		var c: Vector2 = b.p + Vector2(sin(t * 40) * 10 * b.shake, 0)
		Draw.balloon(self, c, b.r, b.col)
		Draw.text(self, c + Vector2(0, -4), b.letter, int(b.r * 1.15), Color.WHITE, b.col.darkened(0.35), 10)
	for p in pops:
		var k: float = p.t / 0.9
		for j in 10:
			var a := TAU * j / 10
			var q: Vector2 = p.p + Vector2(cos(a), sin(a)) * p.r * (0.5 + k * 1.3)
			draw_rect(Rect2(q - Vector2(6, 6) * (1 - k), Vector2(12, 12) * (1 - k)), p.c)
		Draw.text(self, p.p + Vector2(0, -70 * k), p.letter, int(110 + 30 * k), Color(1, 1, 1, 1 - k * 0.7), Color(p.c, 1 - k * 0.7), 16)
	# Prompt card: big letter, its word and a little picture.
	var card := Rect2(140, 40, W - 180, 150)
	Draw.rounded_rect(self, Rect2(card.position + Vector2(0, 8), card.size), 40, Color(0, 0, 0, 0.1))
	Draw.rounded_rect(self, card, 40, Color.WHITE)
	Draw.text(self, card.position + Vector2(78, 68), target() + target().to_lower(), 76, Draw.PINK_DARK)
	_picture(card.position + Vector2(card.size.x - 76, 75), 50)
	var mid := card.position.x + 150 + (card.size.x - 290) / 2
	Draw.text(self, Vector2(mid, card.position.y + 52), "is for", 34, Draw.INK)
	Draw.text(self, Vector2(mid, card.position.y + 96), word(), 46, Draw.ORANGE)
	for i in NEED:
		draw_circle(Vector2(mid - 20 + i * 40, card.position.y + 134), 9, Draw.PINK if i < popped else Color("e3e8f0"))
	draw_back()


func _picture(c: Vector2, r: float) -> void:
	match target():
		"A":
			Draw.fruit(self, "apple", c, r * 0.9)
		"B":
			draw_circle(c, r * 0.8, Draw.BLUE)
			draw_arc(c, r * 0.8, -0.6, 0.6, 12, Color.WHITE, r * 0.18)
			draw_arc(c, r * 0.8, PI - 0.6, PI + 0.6, 12, Color.WHITE, r * 0.18)
			draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.12, Color(1, 1, 1, 0.6))
		"C":
			for side in [-1, 1]:
				draw_colored_polygon(PackedVector2Array([c + Vector2(side * r * 0.75, -r * 0.2), c + Vector2(side * r * 0.65, -r * 0.95), c + Vector2(side * r * 0.2, -r * 0.6)]), Draw.ORANGE)
			draw_circle(c, r * 0.72, Draw.ORANGE)
			draw_circle(c + Vector2(-r * 0.27, -r * 0.1), r * 0.1, Draw.INK)
			draw_circle(c + Vector2(r * 0.27, -r * 0.1), r * 0.1, Draw.INK)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.08, r * 0.1), c + Vector2(r * 0.08, r * 0.1), c + Vector2(0, r * 0.2)]), Draw.PINK)
			for side in [-1, 1]:
				for k in 2:
					draw_line(c + Vector2(side * r * 0.3, r * (0.2 + k * 0.12)), c + Vector2(side * r * 0.95, r * (0.12 + k * 0.22)), Draw.INK, 2)
		"D":
			Draw.ellipse(self, c + Vector2(r * 0.1, r * 0.3), r * 0.8, r * 0.5, Draw.YELLOW)
			draw_circle(c + Vector2(-r * 0.4, -r * 0.35), r * 0.42, Draw.YELLOW)
			draw_circle(c + Vector2(-r * 0.3, -r * 0.45), r * 0.09, Draw.INK)
			Draw.ellipse(self, c + Vector2(-r * 0.88, -r * 0.28), r * 0.26, r * 0.12, Draw.ORANGE)
			Draw.ellipse(self, c + Vector2(r * 0.3, r * 0.2), r * 0.35, r * 0.2, Color("ffc21a"), -0.3)
		"E":
			Draw.ellipse(self, c, r * 0.62, r * 0.82, Color("fff3df"))
			Draw.ellipse(self, c, r * 0.62, r * 0.82, Color("fff3df"))
			draw_arc(c, r * 0.62, 0, TAU, 30, Color("e8d4b0"), 3, true)
			Draw.ellipse(self, c + Vector2(-r * 0.2, -r * 0.35), r * 0.12, r * 0.2, Color(1, 1, 1, 0.9), 0.3)
