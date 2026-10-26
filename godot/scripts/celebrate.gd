class_name Celebrate
extends Node2D
## "Yay!" overlay: confetti, a big star, then calls done.

var stars := 1
var done := Callable()
var _t := 0.0
var _confetti: Array[Dictionary] = []
var _finished := false
var _jelly: Jelly


func _ready() -> void:
	var s := get_viewport_rect().size
	for i in 90:
		_confetti.append({
			"p": Vector2(randf() * s.x, randf_range(-s.y * 0.6, -20)),
			"v": Vector2(randf_range(-60, 60), randf_range(220, 520)),
			"r": randf() * TAU, "w": randf_range(-6, 6),
			"c": [Draw.PINK, Draw.YELLOW, Draw.BLUE, Draw.GREEN, Draw.PURPLE, Draw.ORANGE][i % 6],
			"size": randf_range(10, 20),
		})
	_jelly = Jelly.new()
	_jelly.size = 220
	_jelly.mood = "giggle"
	_jelly.position = Vector2(s.x / 2, s.y * 0.82)
	add_child(_jelly)
	Audio.sfx("yay")
	Voice.say(["Yay! Well done!", "Hooray! You did it!", "Great job!"].pick_random())


func _process(delta: float) -> void:
	_t += delta
	for c in _confetti:
		c.p += c.v * delta
		c.r += c.w * delta
	_jelly.bob = Screen.hop(_t, 150, 50)
	if fmod(_t, 0.4) < delta:
		_jelly.poke(0.25)
	if _t > 2.8:
		_finish()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and _t > 0.8:
		get_viewport().set_input_as_handled()
		_finish()
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	var f := done
	queue_free()
	if f.is_valid():
		f.call()


func _draw() -> void:
	var s := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, min(0.78, _t * 2.5)))
	var c := Vector2(s.x / 2, s.y * 0.3)
	var grow: float = min(1.0, _t * 3.0)
	var pop: float = grow * (1.0 + 0.12 * sin(min(_t, 1.0) * PI * 3) * (1 - min(_t, 1.0)))
	# Sun rays behind the star.
	for i in 12:
		var a := _t * 0.6 + TAU * i / 12
		var pts := PackedVector2Array([c, c + Vector2(cos(a - 0.12), sin(a - 0.12)) * 420 * pop, c + Vector2(cos(a + 0.12), sin(a + 0.12)) * 420 * pop])
		draw_colored_polygon(pts, Color(1, 0.85, 0.2, 0.25))
	Draw.star(self, c + Vector2(0, 10), 190 * pop, Color("e6a800"), sin(_t * 2) * 0.08)
	Draw.star(self, c, 190 * pop, Draw.YELLOW, sin(_t * 2) * 0.08)
	Draw.star(self, c + Vector2(-20, -25), 70 * pop, Color(1, 1, 1, 0.35), sin(_t * 2) * 0.08)
	if grow >= 1.0:
		Draw.text(self, c + Vector2(0, 10), "+%d" % stars, 96, Color.WHITE, Draw.ORANGE, 18)
		Draw.text(self, Vector2(s.x / 2, s.y * 0.53), "Yay! Well done!", 72, Draw.PINK, Color.WHITE, 22)
	for k in _confetti:
		draw_set_transform(k.p, k.r)
		draw_rect(Rect2(-k.size / 2, -k.size / 4, k.size, k.size / 2), k.c)
	draw_set_transform(Vector2.ZERO)
