extends Screen
## Shape Sorter: drag each shape into the hole that matches. Teaches shape names.

const ROUNDS := [
	["circle", "square", "triangle"],
	["star", "heart", "circle"],
	["triangle", "star", "square", "heart"],
]
const COLORS := [Color("ff4a3d"), Color("3b8bff"), Color("ffc21a"), Color("2fbf71"), Color("a05cff")]
const R := 70.0

var round_i := 0
var holes: Array[Dictionary] = []
var pieces: Array[Dictionary] = []
var jelly: Jelly
var _hold := -1
var _grab := Vector2.ZERO
var _between := 0.0
var _finished := false
var _sparks: Array[Dictionary] = []


func _ready() -> void:
	jelly = Jelly.new()
	jelly.color = Draw.PURPLE
	add_child(jelly)
	super._ready()
	_start_round()


func layout() -> void:
	add_back(func() -> void: main.show_screen("games"))
	jelly.size = 160
	jelly.position = Vector2(W - 110, H - 30)
	_place()


func _start_round() -> void:
	var kinds: Array = ROUNDS[round_i]
	holes.clear()
	pieces.clear()
	var order := range(kinds.size())
	order.shuffle()
	for i in kinds.size():
		holes.append({"kind": kinds[i], "p": Vector2.ZERO, "filled": false})
		pieces.append({"kind": kinds[order[i]], "col": COLORS[(round_i * 2 + i) % COLORS.size()], "home": Vector2.ZERO, "p": Vector2.ZERO, "placed": false, "shake": 0.0})
	_place()
	for pc in pieces:
		pc.p = pc.home + Vector2(0, 300)
	Voice.say("Put the shapes in the holes!")


## Holes sit in the board at the top, pieces on the floor below.
func _place() -> void:
	var n := holes.size()
	if n == 0:
		return
	var cols: int = n if n <= 3 else 2
	var board := _board()
	for i in n:
		var cx := board.position.x + board.size.x * (i % cols + 0.5) / cols
		var cy: float = board.position.y + board.size.y * (int(i / cols) + 0.5) / ceil(n / float(cols))
		holes[i].p = Vector2(cx, cy)
	var floor_y := H - 330.0
	for i in n:
		var pc := pieces[i]
		var home := Vector2(W * (i + 0.7) / (n + 0.4), floor_y + (i % 2) * 90 - 40)
		pc.home = home
		if pc.placed:
			pc.p = holes.filter(func(h: Dictionary) -> bool: return h.kind == pc.kind)[0].p
		elif _hold != i:
			pc.p = home


func _board() -> Rect2:
	var n := holes.size()
	var h := 250.0 if n <= 3 else 420.0
	return Rect2(40, 220, W - 80, h)


func tick(delta: float) -> void:
	for i in pieces.size():
		var pc := pieces[i]
		pc.shake = max(0.0, pc.shake - delta * 2)
		if i != _hold and not pc.placed:
			pc.p = pc.p.lerp(pc.home, min(1.0, delta * 8))
	for s in _sparks:
		s.t += delta
	_sparks = _sparks.filter(func(s: Dictionary) -> bool: return s.t < 0.8)
	if _hold >= 0:
		jelly.look = ((pieces[_hold].p - jelly.position) / 400.0).limit_length(1.0)
	else:
		jelly.look = Vector2(-0.5, -0.6)
	if _between > 0:
		_between -= delta
		if _between <= 0:
			round_i += 1
			if round_i >= ROUNDS.size():
				_finished = true
				main.celebrate("games")
			else:
				_start_round()


func press(p: Vector2) -> void:
	if _between > 0 or _finished:
		return
	for i in range(pieces.size() - 1, -1, -1):
		var pc := pieces[i]
		if not pc.placed and p.distance_to(pc.p) < R + 24:
			_hold = i
			_grab = pc.p - p
			Audio.sfx("tap", 1.2)
			# Draw the held piece on top.
			return


func drag(p: Vector2) -> void:
	if _hold >= 0:
		pieces[_hold].p = p + _grab


func release(_p: Vector2) -> void:
	if _hold < 0:
		return
	var pc := pieces[_hold]
	_hold = -1
	for h in holes:
		if h.filled or pc.p.distance_to(h.p) > R * 1.1:
			continue
		if h.kind == pc.kind:
			pc.placed = true
			pc.p = h.p
			h.filled = true
			Audio.sfx("snap")
			Voice.say(pc.kind.capitalize() + "!")
			_sparks.append({"p": h.p, "c": pc.col, "t": 0.0})
			jelly.poke(0.4)
			jelly.mouth_open = 1.0
			if pieces.all(func(x: Dictionary) -> bool: return x.placed):
				_between = 1.6
				Audio.sfx("chime")
				jelly.mood = "giggle"
				get_tree().create_timer(1.4).timeout.connect(func() -> void:
					if is_instance_valid(jelly):
						jelly.mood = "smile")
		else:
			pc.shake = 1.0
			Audio.sfx("wrong")
			Voice.say("Hmm, that's a %s hole!" % h.kind)
		return


## For tests: drops piece [param i] into the hole at [param at].
func drop(i: int, at: Vector2) -> void:
	press(pieces[i].p)
	drag(at)
	release(at)


func _draw() -> void:
	Draw.gradient_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]), Color("ffd6ef"), Color("fff4d6"))
	draw_rect(Rect2(0, H - 420, W, 420), Color("ffe2a8"))
	for i in 9:
		draw_line(Vector2(0, H - 420 + i * 50), Vector2(W, H - 420 + i * 50), Color(0, 0, 0, 0.04), 3)
	Draw.text(self, Vector2(W / 2 + 30, 92), "Shape Sorter", 64, Color.WHITE, Draw.PURPLE, 18)
	# Board with holes.
	var b := _board()
	Draw.rounded_rect(self, Rect2(b.position + Vector2(0, 14), b.size), 40, Color("c97a2c"))
	Draw.rounded_rect(self, b, 40, Color("f2a65a"))
	for i in 5:
		draw_line(b.position + Vector2(30, 40 + i * b.size.y / 5), b.position + Vector2(b.size.x - 30, 30 + i * b.size.y / 5), Color(0, 0, 0, 0.05), 6)
	for h in holes:
		Draw.hole(self, h.kind, h.p, R)
	for s in _sparks:
		var k: float = s.t / 0.8
		for j in 10:
			var a := TAU * j / 10
			Draw.star(self, s.p + Vector2(cos(a), sin(a)) * R * (0.8 + k * 1.4), 14 * (1 - k), Draw.YELLOW)
	# Placed pieces first, then loose ones, then the one in the hand.
	for pc in pieces:
		if pc.placed:
			Draw.shape(self, pc.kind, pc.p, R * 0.94, pc.col)
	for i in pieces.size():
		var pc := pieces[i]
		if not pc.placed and i != _hold:
			var off := Vector2(sin(t * 40) * 10 * pc.shake, sin(t * 3 + i) * 4)
			Draw.ellipse(self, pc.p + Vector2(0, R * 0.95), R * 0.8, R * 0.16, Color(0, 0, 0, 0.12))
			Draw.shape(self, pc.kind, pc.p + off, R * 0.94, pc.col)
	if _hold >= 0:
		var pc := pieces[_hold]
		Draw.ellipse(self, pc.p + Vector2(0, R * 1.3), R * 0.7, R * 0.14, Color(0, 0, 0, 0.15))
		Draw.shape(self, pc.kind, pc.p, R * 1.05, pc.col)
	if _between > 0 or _finished:
		Draw.text(self, Vector2(W / 2, b.end.y + 70), "Yay!", 72, Draw.PINK, Color.WHITE, 18)
	draw_back()
