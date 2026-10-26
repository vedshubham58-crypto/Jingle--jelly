extends Screen
## Bubble Pop: "Pop 3 red bubbles!" Teaches colours and counting.

const COLORS := {
	"red": Color("ff4a3d"),
	"blue": Color("3b8bff"),
	"green": Color("2fbf71"),
	"yellow": Color("ffc21a"),
	"purple": Color("a05cff"),
}
const ROUNDS := [["red", 2], ["blue", 3], ["yellow", 1], ["green", 4], ["purple", 3], ["red", 5]]

var round_i := 0
var popped := 0
var bubbles: Array[Dictionary] = []
var pops: Array[Dictionary] = []  # burst rings and numbers
var jelly: Jelly
var _spawn := 0.0
var _between := 0.0
var _finished := false


func _ready() -> void:
	jelly = Jelly.new()
	jelly.color = Draw.GREEN
	add_child(jelly)
	super._ready()
	_announce()


func layout() -> void:
	add_back(func() -> void: main.show_screen("games"))
	jelly.size = 170
	jelly.position = Vector2(W - 120, H - 40)


func target() -> String:
	return ROUNDS[min(round_i, ROUNDS.size() - 1)][0]


func needed() -> int:
	return ROUNDS[min(round_i, ROUNDS.size() - 1)][1]


func _announce() -> void:
	var n := needed()
	Voice.say("Pop %d %s bubble%s!" % [n, target(), "" if n == 1 else "s"])


func tick(delta: float) -> void:
	_spawn -= delta
	if _spawn <= 0 and bubbles.size() < 9 and not _finished:
		_spawn = randf_range(0.45, 0.8)
		var is_target := randf() < 0.45
		var col: String = target() if is_target else COLORS.keys().filter(func(k: String) -> bool: return k != target()).pick_random()
		var r := randf_range(55, 85)
		bubbles.append({"p": Vector2(randf_range(r + 10, W - r - 10), H + r), "r": r, "col": col, "v": randf_range(90, 150), "ph": randf() * TAU, "shake": 0.0})
	for b in bubbles:
		b.p.y -= b.v * delta
		b.p.x += sin(t * 1.5 + b.ph) * 0.8
		b.shake = max(0.0, b.shake - delta * 2)
	bubbles = bubbles.filter(func(b: Dictionary) -> bool: return b.p.y > -b.r)
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
	for i in range(bubbles.size() - 1, -1, -1):
		var b := bubbles[i]
		if p.distance_to(b.p) < b.r + 14:
			if b.col == target():
				bubbles.remove_at(i)
				popped += 1
				Audio.sfx("pop", 0.9 + popped * 0.1)
				pops.append({"p": b.p, "c": COLORS[b.col], "n": popped, "t": 0.0, "r": b.r})
				Voice.say(str(popped))
				jelly.poke(0.4)
				jelly.mouth_open = 1.0
				if popped >= needed():
					_between = 1.6
					Audio.sfx("chime")
					jelly.mood = "giggle"
					get_tree().create_timer(1.4).timeout.connect(func() -> void:
						if is_instance_valid(jelly):
							jelly.mood = "smile")
			else:
				b.shake = 1.0
				Audio.sfx("wrong")
				Voice.say("That one is %s!" % b.col)
			return


func _draw() -> void:
	Draw.gradient_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]), Color("6fd0ff"), Color("d9f4ff"))
	for i in 4:
		var cx := fmod(120.0 + i * 230 + t * 12, W + 200) - 100
		for k in 3:
			draw_circle(Vector2(cx + k * 42, 330 + i * 190 - (k % 2) * 20), 36, Color(1, 1, 1, 0.75))
	for b in bubbles:
		var off := Vector2(sin(t * 40) * 10 * b.shake, 0)
		Draw.bubble(self, b.p + off, b.r, COLORS[b.col])
	for p in pops:
		var k: float = p.t / 0.9
		draw_arc(p.p, p.r * (1 + k), 0, TAU, 32, Color(p.c, 1 - k), 8 * (1 - k))
		for j in 8:
			var a := TAU * j / 8
			draw_circle(p.p + Vector2(cos(a), sin(a)) * p.r * (0.6 + k * 1.2), 7 * (1 - k), p.c)
		Draw.text(self, p.p + Vector2(0, -60 * k), str(p.n), int(96 + 30 * k), Color(1, 1, 1, 1 - k * 0.7), Color(p.c, 1 - k * 0.7), 16)
	# Prompt card: colour swatch, words, and dots for counting.
	var card := Rect2(140, 40, W - 180, 150)
	Draw.rounded_rect(self, Rect2(card.position + Vector2(0, 8), card.size), 40, Color(0, 0, 0, 0.1))
	Draw.rounded_rect(self, card, 40, Color.WHITE)
	var tc: Color = COLORS[target()]
	Draw.bubble(self, card.position + Vector2(80, 75), 50, tc)
	var n := needed()
	var label := "Pop %d %s!" % [n, target()]
	if _finished or _between > 0:
		label = "Yay!"
	Draw.text(self, Vector2(card.position.x + 80 + (card.size.x - 80) / 2, card.position.y + 52), label, 46, tc.darkened(0.25))
	for i in n:
		var dp := Vector2(card.position.x + 80 + (card.size.x - 80) / 2 - (n - 1) * 26 + i * 52, card.position.y + 112)
		draw_circle(dp, 20, tc if i < popped else Color("e3e8f0"))
		if i < popped:
			Draw.text(self, dp, str(i + 1), 26, Color.WHITE)
	draw_back()
