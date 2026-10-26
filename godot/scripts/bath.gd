extends Screen
## Bath Time: scrub baby's hair, hands and feet with the sponge, then rinse.

const STEPS := [
	{"part": "hair", "say": "Wash baby's hair!", "spots": ["hair"]},
	{"part": "hands", "say": "Now wash baby's hands!", "spots": ["hand_l", "hand_r"]},
	{"part": "feet", "say": "Now wash baby's feet!", "spots": ["foot_l", "foot_r"]},
]

var step := 0
var dirt := {}  # spot -> 0..1 dirt left
var foam: Array[Dictionary] = []  # soap bubbles stuck on baby
var drops: Array[Dictionary] = []
var sponge := Vector2(-999, -999)
var scrubbing := false
var rinsing := 0.0
var _scrub_cd := 0.0
var _last_drag := Vector2.ZERO
var _giggle := 0.0
var _finished := false
var duck_x := 0.0


func _ready() -> void:
	for st in STEPS:
		for s in st.spots:
			dirt[s] = 1.0
	super._ready()
	Voice.say(STEPS[0].say)


func layout() -> void:
	add_back(func() -> void: main.show_screen("home"))
	duck_x = W * 0.7


func tub_rect() -> Rect2:
	return Rect2(40, H * 0.56, W - 80, 250)


func spot_pos(id: String) -> Vector2:
	var tr := tub_rect()
	var head := _head_pos(tr)
	match id:
		"hair":
			return head + Vector2(0, -100)
		"hand_l":
			return Vector2(tr.position.x + 55, tr.position.y - 8)
		"hand_r":
			return Vector2(tr.position.x + 375, tr.position.y - 8)
		"foot_l":
			return Vector2(tr.end.x - 150, tr.position.y - 50)
		"foot_r":
			return Vector2(tr.end.x - 70, tr.position.y - 62)
	return Vector2.ZERO


func _head_pos(tr: Rect2) -> Vector2:
	return Vector2(tr.position.x + 215, tr.position.y - 100)


func current_spots() -> Array:
	if step >= STEPS.size():
		return []
	return STEPS[step].spots


func press(p: Vector2) -> void:
	if step >= STEPS.size():
		if not _finished and _shower_rect().grow(30).has_point(p):
			_rinse()
		return
	scrubbing = true
	sponge = p
	_last_drag = p


func drag(p: Vector2) -> void:
	if not scrubbing:
		return
	var moved := p.distance_to(_last_drag)
	_last_drag = p
	sponge = p
	for s in current_spots():
		if dirt[s] > 0 and p.distance_to(spot_pos(s)) < 85:
			dirt[s] = max(0.0, dirt[s] - moved / 700.0)
			if randf() < 0.5:
				foam.append({"p": spot_pos(s) + Vector2(randf_range(-55, 55), randf_range(-45, 45)), "r": randf_range(10, 24), "c": [Color("ffffff"), Color("d8f3ff"), Color("ffd6ec")].pick_random()})
			if _scrub_cd <= 0:
				Audio.sfx("scrub", randf_range(0.9, 1.15), -3.0)
				_scrub_cd = 0.25
			if dirt[s] == 0.0:
				Audio.sfx("chime", 1.2, -4.0)
				_giggle = 1.0
	_check_step()


func release(_p: Vector2) -> void:
	scrubbing = false
	sponge = Vector2(-999, -999)


func _check_step() -> void:
	if step >= STEPS.size():
		return
	for s in current_spots():
		if dirt[s] > 0:
			return
	step += 1
	Audio.sfx("chime")
	if step < STEPS.size():
		Voice.say("Great! " + STEPS[step].say)
	else:
		scrubbing = false
		sponge = Vector2(-999, -999)
		Voice.say("All clean! Tap the shower to rinse!")


func _shower_rect() -> Rect2:
	return Rect2(W - 250, 200, 200, 200)


func _rinse() -> void:
	if rinsing > 0:
		return
	rinsing = 2.2
	Audio.sfx("splash")
	Voice.say("Splish splash!")


func tick(delta: float) -> void:
	_scrub_cd -= delta
	_giggle = max(0.0, _giggle - delta * 1.5)
	duck_x = W * 0.68 + sin(t * 0.8) * 60
	if rinsing > 0:
		rinsing -= delta
		for i in 6:
			drops.append({"p": _shower_rect().get_center() + Vector2(randf_range(-50, 30), 20), "v": Vector2(randf_range(-260, -120), randf_range(450, 650))})
		if foam.size() > 0 and randf() < 0.6:
			foam.pop_back()
			if foam.size() > 0:
				foam.pop_front()
		if rinsing <= 0 and not _finished:
			_finished = true
			foam.clear()
			main.celebrate("home")
	for d in drops:
		d.p += d.v * delta
	drops = drops.filter(func(d: Dictionary) -> bool: return d.p.y < H)


func _draw() -> void:
	# Tiled bathroom wall and floor.
	draw_rect(Rect2(0, 0, W, H), Color("bdf0ff"))
	for y in range(0, int(H * 0.62), 90):
		for x in range(0, int(W), 90):
			Draw.rounded_rect(self, Rect2(x + 4, y + 4, 82, 82), 12, Color("a6e6fb"))
	draw_rect(Rect2(0, H * 0.62, W, H * 0.38), Color("ffe2b8"))
	var tr := tub_rect()
	# Water behind baby.
	Draw.rounded_rect(self, Rect2(tr.position + Vector2(20, -10), Vector2(tr.size.x - 40, 60)), 30, Color("7fd3ff"))
	_draw_baby(tr)
	# Bath tub front.
	Draw.rounded_rect(self, Rect2(tr.position + Vector2(0, 24), tr.size), 120, Color("d9e6f2"))
	Draw.rounded_rect(self, tr, 120, Color.WHITE)
	Draw.rounded_rect(self, Rect2(tr.position + Vector2(30, 110), Vector2(tr.size.x - 60, 34)), 17, Color("ffb3d9"))
	for i in 7:
		draw_circle(tr.position + Vector2(80 + i * (tr.size.x - 160) / 6.0, 190), 14, Color("bfe9ff"))
	Draw.rounded_rect(self, Rect2(tr.position + Vector2(50, 50), Vector2(150, 22)), 11, Color(0.85, 0.92, 1.0, 0.9))
	for x in [tr.position.x + 90, tr.end.x - 90]:
		Draw.ellipse(self, Vector2(x, tr.end.y + 34), 30, 18, Color("f2b134"))
	# Foam on the water line.
	for i in 14:
		Draw.bubble(self, Vector2(tr.position.x + 40 + i * (tr.size.x - 80) / 13.0, tr.position.y + 6 + sin(t * 2 + i) * 4), 22 + (i % 3) * 6, Color.WHITE)
	# Rubber duck.
	var dp := Vector2(duck_x, tr.position.y - 18 + sin(t * 3) * 5)
	Draw.ellipse(self, dp + Vector2(0, 12), 40, 26, Draw.YELLOW)
	draw_circle(dp + Vector2(-22, -18), 22, Draw.YELLOW)
	Draw.ellipse(self, dp + Vector2(-44, -12), 14, 7, Draw.ORANGE)
	draw_circle(dp + Vector2(-26, -24), 4, Draw.INK)
	# Soap foam the child made.
	for f in foam:
		Draw.bubble(self, f.p, f.r, f.c)
	# Shower head (button for rinsing).
	var sr := _shower_rect()
	var ready := step >= STEPS.size() and not _finished
	var sc := sr.get_center()
	var glow := (0.5 + 0.5 * sin(t * 6)) if ready else 0.0
	if ready:
		draw_circle(sc, 105 + glow * 14, Color(1, 1, 1, 0.6))
	draw_line(Vector2(W - 30, 0), Vector2(W - 30, sc.y - 70), Color("9aa3b5"), 18)
	draw_line(Vector2(W - 30, sc.y - 70), sc + Vector2(30, -50), Color("9aa3b5"), 18)
	Draw.ellipse(self, sc, 78, 52, Color("c3cbd8"), -0.5)
	Draw.ellipse(self, sc + Vector2(-6, 8), 64, 38, Color("e6ebf2"), -0.5)
	for k in 7:
		var hp := sc + Vector2(-6, 8) + Vector2(cos(k * 0.9) * 36, sin(k * 0.9) * 18).rotated(-0.5)
		draw_circle(hp, 5, Color("9aa3b5"))
	for d in drops:
		Draw.ellipse(self, d.p, 5, 11, Color("3fb6ff"), 0.2)
	# Instruction.
	var msg: String
	if step < STEPS.size():
		msg = STEPS[step].say
		for s in current_spots():
			if dirt[s] > 0:
				var hp: Vector2 = spot_pos(s) + Vector2(0, -110 + sin(t * 5) * 12)
				draw_colored_polygon(PackedVector2Array([hp + Vector2(-20, -30), hp + Vector2(20, -30), hp + Vector2(0, 0)]), Draw.PINK)
	else:
		msg = "Tap the shower!" if not _finished else "All clean!"
	Draw.rounded_rect(self, Rect2(140, 50, W - 380, 90), 45, Color.WHITE)
	Draw.text(self, Vector2(140 + (W - 380) / 2.0, 95), msg, 36 if msg.length() < 18 else 30, Draw.INK)
	# Progress: three little stars.
	for i in STEPS.size():
		Draw.star(self, Vector2(W / 2 - 60 + i * 60, H - 70), 26, Draw.YELLOW if i < step else Color(1, 1, 1, 0.6))
	draw_back()
	# Sponge under the finger.
	if sponge.x > -900:
		Draw.rounded_rect(self, Rect2(sponge + Vector2(-50, -32), Vector2(100, 64)), 22, Color("ffd23f"))
		for k in 5:
			draw_circle(sponge + Vector2(-30 + k * 15, -10 + (k % 2) * 18), 5, Color("e6a800"))


func _draw_baby(tr: Rect2) -> void:
	var head := _head_pos(tr)
	# Body / shoulders in the water.
	Draw.ellipse(self, head + Vector2(0, 125), 120, 70, Draw.SKIN.darkened(0.04))
	# Arms resting on the tub edge.
	for side in [-1, 1]:
		var hand := spot_pos("hand_l" if side < 0 else "hand_r")
		draw_line(head + Vector2(side * 85, 110), hand + Vector2(0, 10), Draw.SKIN, 40)
		draw_circle(hand, 32, Draw.SKIN)
		_dirt(hand, "hand_l" if side < 0 else "hand_r")
	# Feet up at the other end.
	for id in ["foot_l", "foot_r"]:
		var f := spot_pos(id)
		Draw.ellipse(self, f, 36, 48, Draw.SKIN, -0.25)
		for k in 4:
			draw_circle(f + Vector2(-22 + k * 13, -40 + abs(k - 1.5) * 4).rotated(-0.25), 9, Draw.SKIN)
		_dirt(f, id)
	# Head.
	draw_circle(head + Vector2(-102, 6), 22, Draw.SKIN)
	draw_circle(head + Vector2(102, 6), 22, Draw.SKIN)
	draw_circle(head, 105, Draw.SKIN)
	draw_arc(head + Vector2(10, -104), 20, PI * 0.9, PI * 2.2, 14, Color("8a5a2b"), 10, true)
	_dirt(spot_pos("hair"), "hair")
	var happy := _giggle > 0 or step >= STEPS.size()
	if happy:
		for side in [-1, 1]:
			draw_arc(head + Vector2(side * 36, 4), 15, PI * 1.1, PI * 1.9, 10, Draw.INK, 6, true)
	else:
		for side in [-1, 1]:
			draw_circle(head + Vector2(side * 36, 0), 13, Draw.INK)
			draw_circle(head + Vector2(side * 36 + 4, -5), 4.5, Color.WHITE)
	Draw.ellipse(self, head + Vector2(-64, 32), 19, 11, Draw.CHEEK)
	Draw.ellipse(self, head + Vector2(64, 32), 19, 11, Draw.CHEEK)
	if happy:
		Draw.ellipse(self, head + Vector2(0, 44), 22, 17, Color("c0503a"))
	else:
		draw_arc(head + Vector2(0, 30), 20, 0.2 * PI, 0.8 * PI, 12, Color("c0503a"), 6, true)


func _dirt(p: Vector2, id: String) -> void:
	var d: float = dirt.get(id, 0.0)
	if d <= 0:
		return
	for k in 4:
		var a := k * 1.7
		Draw.ellipse(self, p + Vector2(cos(a), sin(a)) * 16, 17 * d + 4, 12 * d + 3, Color(0.55, 0.38, 0.2, 0.75 * d))
