extends Screen
## Feed Jelly: "Give Jelly 3 bananas!" Drag fruit to Jelly's mouth. Teaches
## fruit names and counting.

const ROUNDS := [["apple", 2], ["banana", 3], ["strawberry", 1], ["orange", 4], ["grapes", 2]]
const KINDS := ["apple", "banana", "strawberry", "orange", "grapes"]
const PLURAL := {"apple": "apples", "banana": "bananas", "strawberry": "strawberries", "orange": "oranges", "grapes": "grapes"}
const FR := 54.0

var round_i := 0
var eaten := 0
var fruits: Array[Dictionary] = []
var jelly: Jelly
var _hold := -1
var _grab := Vector2.ZERO
var _between := 0.0
var _finished := false
var _crumbs: Array[Dictionary] = []
var _nope := 0.0


func _ready() -> void:
	jelly = Jelly.new()
	add_child(jelly)
	super._ready()
	_start_round()


func layout() -> void:
	add_back(func() -> void: main.show_screen("games"))
	jelly.size = min(320.0, W * 0.45)
	jelly.position = Vector2(W / 2, H - 392)
	_place()


func target() -> String:
	return ROUNDS[min(round_i, ROUNDS.size() - 1)][0]


func needed() -> int:
	return ROUNDS[min(round_i, ROUNDS.size() - 1)][1]


func _start_round() -> void:
	eaten = 0
	fruits.clear()
	var list: Array[String] = []
	for i in needed() + 1:
		list.append(target())
	var others := KINDS.filter(func(k: String) -> bool: return k != target())
	while list.size() < 8:
		list.append(others.pick_random())
	list.shuffle()
	for k in list:
		fruits.append({"kind": k, "home": Vector2.ZERO, "p": Vector2.ZERO, "eaten": false, "shake": 0.0})
	_place()
	_announce()


func _announce() -> void:
	var n := needed()
	Voice.say("Give Jelly %d %s!" % [n, target() if n == 1 and target() != "grapes" else PLURAL[target()]])


func _place() -> void:
	for i in fruits.size():
		var row := i / 4
		var home := Vector2(W * (i % 4 + 0.5) / 4.0 + (row * 2 - 1) * 20, H - 270 + row * 130)
		fruits[i].home = home
		if i != _hold:
			fruits[i].p = home


func mouth() -> Vector2:
	return jelly.position + Vector2(0, -jelly.size * 0.92 * 0.28 + jelly.bob)


func tick(delta: float) -> void:
	for i in fruits.size():
		var f := fruits[i]
		f.shake = max(0.0, f.shake - delta * 2)
		if i != _hold and not f.eaten:
			f.p = f.p.lerp(f.home, min(1.0, delta * 8))
	for c in _crumbs:
		c.v.y += 900 * delta
		c.p += c.v * delta
		c.t += delta
	_crumbs = _crumbs.filter(func(c: Dictionary) -> bool: return c.t < 0.7)
	_nope = max(0.0, _nope - delta)
	jelly.position.x = W / 2 + sin(_nope * 30) * 14 * _nope
	if _hold >= 0:
		var d: float = fruits[_hold].p.distance_to(mouth())
		jelly.look = ((fruits[_hold].p - mouth()) / 300.0).limit_length(1.0)
		jelly.mood = "wow" if d < 260 else "smile"
	elif jelly.mood == "wow":
		jelly.mood = "smile"
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
	for i in range(fruits.size() - 1, -1, -1):
		var f := fruits[i]
		if not f.eaten and p.distance_to(f.p) < FR + 20:
			_hold = i
			_grab = f.p - p
			Audio.sfx("tap", 1.2)
			return
	if p.distance_to(mouth() + Vector2(0, -jelly.size * 0.2)) < jelly.size * 0.5:
		jelly.poke(0.5)
		Audio.sfx("boing")
		_announce()


func drag(p: Vector2) -> void:
	if _hold >= 0:
		fruits[_hold].p = p + _grab


func release(_p: Vector2) -> void:
	if _hold < 0:
		return
	var f := fruits[_hold]
	_hold = -1
	if f.p.distance_to(mouth()) > 130:
		return
	if f.kind == target():
		f.eaten = true
		eaten += 1
		Audio.sfx("munch")
		Voice.say(str(eaten))
		jelly.poke(0.5)
		jelly.mouth_open = 1.0
		for k in 8:
			_crumbs.append({"p": mouth(), "v": Vector2(randf_range(-220, 220), randf_range(-380, -120)), "t": 0.0, "c": _fruit_color(f.kind)})
		if eaten >= needed():
			_between = 1.8
			Audio.sfx("chime")
			jelly.mood = "giggle"
			Voice.say("Yum yum! Thank you!")
			get_tree().create_timer(1.6).timeout.connect(func() -> void:
				if is_instance_valid(jelly):
					jelly.mood = "smile")
	else:
		f.shake = 1.0
		_nope = 0.6
		Audio.sfx("wrong")
		Voice.say("No thank you! I want %s!" % PLURAL[target()])


## For tests: feeds fruit [param i] to Jelly.
func feed(i: int) -> void:
	press(fruits[i].p)
	drag(mouth())
	release(mouth())


func _fruit_color(kind: String) -> Color:
	return {"apple": Draw.RED, "banana": Draw.YELLOW, "strawberry": Color("ff3b5c"), "orange": Draw.ORANGE, "grapes": Draw.PURPLE}[kind]


func _draw() -> void:
	# Kitchen: striped wall, window, table.
	draw_rect(Rect2(0, 0, W, H), Color("fff1c9"))
	for i in int(W / 60) + 1:
		draw_rect(Rect2(i * 60, 0, 30, H), Color(1, 1, 1, 0.35))
	var win := Rect2(W / 2 - 150, 230, 300, 220)
	Draw.rounded_rect(self, Rect2(win.position - Vector2(14, 14), win.size + Vector2(28, 28)), 30, Color.WHITE)
	Draw.rounded_rect(self, win, 22, Color("9fe0ff"))
	draw_circle(win.position + Vector2(220, 70), 34, Draw.YELLOW)
	draw_line(win.position + Vector2(win.size.x / 2, 0), win.position + Vector2(win.size.x / 2, win.size.y), Color.WHITE, 12)
	draw_line(win.position + Vector2(0, win.size.y / 2), win.position + Vector2(win.size.x, win.size.y / 2), Color.WHITE, 12)
	var table_y := H - 380.0
	draw_rect(Rect2(0, table_y, W, H - table_y), Color("ff9fcf"))
	for i in int(W / 80) + 1:
		for j in 6:
			if (i + j) % 2 == 0:
				draw_rect(Rect2(i * 80, table_y + j * 80, 80, 80), Color(1, 1, 1, 0.35))
	draw_rect(Rect2(0, table_y, W, 14), Color(0, 0, 0, 0.08))
	# Prompt card with dots to count.
	var card := Rect2(140, 40, W - 180, 150)
	Draw.rounded_rect(self, Rect2(card.position + Vector2(0, 8), card.size), 40, Color(0, 0, 0, 0.1))
	Draw.rounded_rect(self, card, 40, Color.WHITE)
	Draw.fruit(self, target(), card.position + Vector2(80, 75), 46)
	var n := needed()
	var label := "Give %d %s" % [n, target() if n == 1 and target() != "grapes" else PLURAL[target()]]
	if _between > 0 or _finished:
		label = "Yum yum!"
	var size := 46
	while size > 28 and Draw.text_width(label, size) > card.size.x - 130:
		size -= 2
	var tc := card.position.x + 80 + (card.size.x - 80) / 2
	Draw.text(self, Vector2(tc, card.position.y + 52), label, size, _fruit_color(target()).darkened(0.3))
	for i in n:
		var dp := Vector2(tc - (n - 1) * 26 + i * 52, card.position.y + 112)
		draw_circle(dp, 20, _fruit_color(target()) if i < eaten else Color("e3e8f0"))
		if i < eaten:
			Draw.text(self, dp, str(i + 1), 26, Color.WHITE)
	# Plates.
	for row in 2:
		Draw.ellipse(self, Vector2(W / 2 + (row * 2 - 1) * 20, H - 270 + row * 130 + 40), W * 0.47, 46, Color(0, 0, 0, 0.08))
		Draw.ellipse(self, Vector2(W / 2 + (row * 2 - 1) * 20, H - 270 + row * 130 + 34), W * 0.46, 42, Color.WHITE)
	for i in fruits.size():
		var f := fruits[i]
		if f.eaten or i == _hold:
			continue
		Draw.fruit(self, f.kind, f.p + Vector2(sin(t * 40) * 10 * f.shake, 0), FR)
	for c in _crumbs:
		draw_circle(c.p, 9 * (1 - c.t / 0.7), c.c)
	draw_back()


func _process(delta: float) -> void:
	super._process(delta)
	# The held fruit is drawn above Jelly by a small overlay node.
	if not has_node("Held"):
		var o := Node2D.new()
		o.name = "Held"
		o.draw.connect(func() -> void:
			if _hold >= 0 and _hold < fruits.size():
				var f := fruits[_hold]
				Draw.fruit(o, f.kind, f.p, FR * 1.15))
		add_child(o)
	get_node("Held").queue_redraw()
