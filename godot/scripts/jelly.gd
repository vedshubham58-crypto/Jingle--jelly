class_name Jelly
extends Node2D
## Jelly, the wobbly mascot (and friends in other colours). The node's origin is
## the middle of Jelly's base. poke() makes it wobble, mouth_open makes it sing.

var color := Draw.PINK
var size := 260.0
var mood := "smile"  # smile, sing, wow, giggle
var mouth_open := 0.0
var look := Vector2.ZERO  # -1..1 where the eyes look
var bob := 0.0  # extra vertical offset (hops)

var _sq := 0.0
var _sqv := 0.0
var _blink := 0.0
var _next_blink := 2.0
var _t := 0.0


func poke(strength := 0.35) -> void:
	_sqv += strength * 8.0


func _process(delta: float) -> void:
	_t += delta
	# Springy squash and stretch.
	var acc := -140.0 * _sq - 7.0 * _sqv
	_sqv += acc * delta
	_sq += _sqv * delta
	_next_blink -= delta
	if _next_blink <= 0:
		_blink = 0.16
		_next_blink = randf_range(1.8, 4.5)
	_blink = max(0.0, _blink - delta)
	mouth_open = max(0.0, mouth_open - delta * 2.5)
	queue_redraw()


static func body_points(w: float, h: float, n := 64) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var x := cos(a)
		var y := sin(a)
		var px: float
		var py: float
		if y < 0.0:
			px = w / 2 * sign(x) * pow(abs(x), 0.8)
			py = -h * 0.16 - pow(abs(y), 0.62) * h * 0.84
			py -= h * 0.06 * exp(-pow(px / (w * 0.07), 2))  # the little drip on top
		else:
			px = w / 2 * sign(x) * pow(abs(x), 0.55)
			py = -h * 0.16 + y * h * 0.16
		pts.append(Vector2(px, py))
	return pts


func _draw() -> void:
	var breathe := sin(_t * 2.4) * 0.02
	var s: float = clamp(_sq + breathe, -0.35, 0.35)
	var w := size * (1.0 + s)
	var h := size * 0.92 * (1.0 - s)
	var lift := bob
	# Shadow stays on the floor.
	Draw.ellipse(self, Vector2(0, 4), w * 0.5 * (1.0 + lift / 300.0), size * 0.06, Color(0, 0, 0, 0.13))
	draw_set_transform(Vector2(0, lift))
	var pts := body_points(w, h)
	Draw.gradient_polygon(self, pts, color.lightened(0.35), color.darkened(0.18))
	# Shine.
	Draw.ellipse(self, Vector2(-w * 0.24, -h * 0.74), w * 0.13, h * 0.07, Color(1, 1, 1, 0.5), -0.55)
	Draw.ellipse(self, Vector2(-w * 0.34, -h * 0.58), w * 0.03, h * 0.03, Color(1, 1, 1, 0.45))
	# Eyes.
	var ey := -h * 0.5
	var ex := w * 0.17
	var er := size * 0.1
	if mood == "giggle":
		for side in [-1, 1]:
			var c := Vector2(side * ex, ey + er * 0.2)
			draw_arc(c, er * 0.7, PI * 1.1, PI * 1.9, 16, Draw.INK, size * 0.035, true)
	else:
		var open := 1.0 if _blink <= 0.0 else 0.12
		var wide := 1.18 if mood == "wow" else 1.0
		for side in [-1, 1]:
			var c := Vector2(side * ex, ey)
			Draw.ellipse(self, c, er * wide, er * 1.2 * open * wide, Color.WHITE)
			if open > 0.5:
				var pc := c + Vector2(look.x * er * 0.3 + er * 0.12, look.y * er * 0.3 + er * 0.1)
				Draw.ellipse(self, pc, er * 0.62, er * 0.75, Draw.INK)
				draw_circle(pc + Vector2(er * 0.22, -er * 0.28), er * 0.22, Color.WHITE)
	# Cheeks.
	for side in [-1, 1]:
		Draw.ellipse(self, Vector2(side * w * 0.3, -h * 0.33), size * 0.065, size * 0.038, Draw.CHEEK)
	# Mouth.
	var mc := Vector2(0, -h * 0.28)
	var dark := color.darkened(0.6)
	if mood == "sing" or mood == "wow" or mouth_open > 0.05:
		var o: float = max(mouth_open, 0.55 if mood == "wow" else 0.3)
		# A happy "D" shaped open mouth: flat top, round bottom.
		var mw := size * (0.075 + 0.02 * o)
		var mh := size * (0.04 + 0.08 * o)
		var top := mc + Vector2(0, -size * 0.01)
		var mouth := PackedVector2Array()
		for i in 17:
			var a := PI * i / 16.0
			mouth.append(top + Vector2(cos(a) * mw, sin(a) * mh))
		draw_colored_polygon(mouth, dark)
		Draw.ellipse(self, top + Vector2(0, mh * 0.72), mw * 0.6, mh * 0.26, Color("ff7aa8"))
	else:
		draw_arc(mc + Vector2(0, -size * 0.03), size * 0.08, 0.15 * PI, 0.85 * PI, 20, dark, size * 0.03, true)
	draw_set_transform(Vector2.ZERO)
