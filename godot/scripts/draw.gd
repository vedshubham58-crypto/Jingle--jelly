class_name Draw
## Shape helpers shared by every screen. Everything in the game is drawn in
## code, so there are no image files to license.

const FONT_PATH := "res://fonts/Baloo2-ExtraBold.ttf"

const INK := Color("1d2a44")
const PINK := Color("ff5cab")
const PINK_DARK := Color("e0287f")
const YELLOW := Color("ffd23f")
const YELLOW_LIGHT := Color("ffe27a")
const BLUE := Color("3fb6ff")
const GREEN := Color("2fbf71")
const RED := Color("ff4a3d")
const ORANGE := Color("ff8a3d")
const PURPLE := Color("8b5cff")
const SKIN := Color("ffd1a8")
const CHEEK := Color(1.0, 0.56, 0.75, 0.75)

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH)
	return _font


static func ellipse_points(c: Vector2, rx: float, ry: float, n := 40, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	ci.draw_colored_polygon(ellipse_points(c, rx, ry, 40, rot), col)


static func circle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r, col)


static func ring(ci: CanvasItem, c: Vector2, r: float, col: Color, width := 4.0) -> void:
	ci.draw_arc(c, r, 0, TAU, 48, col, width, true)


static func rounded_rect_points(r: Rect2, rad: float, seg := 8) -> PackedVector2Array:
	rad = min(rad, r.size.x / 2, r.size.y / 2)
	var pts := PackedVector2Array()
	var corners := [
		[r.position + Vector2(r.size.x - rad, rad), -PI / 2],
		[r.position + Vector2(r.size.x - rad, r.size.y - rad), 0.0],
		[r.position + Vector2(rad, r.size.y - rad), PI / 2],
		[r.position + Vector2(rad, rad), PI],
	]
	for c in corners:
		for i in seg + 1:
			var a: float = c[1] + PI / 2 * i / seg
			pts.append(c[0] + Vector2(cos(a), sin(a)) * rad)
	return pts


static func rounded_rect(ci: CanvasItem, r: Rect2, rad: float, col: Color) -> void:
	ci.draw_colored_polygon(rounded_rect_points(r, rad), col)


## A chunky button face: a darker "lip" underneath, then the face.
static func button_face(ci: CanvasItem, r: Rect2, rad: float, col: Color, pressed := false) -> void:
	var lip := 10.0
	if not pressed:
		rounded_rect(ci, Rect2(r.position + Vector2(0, lip), r.size), rad, col.darkened(0.28))
		rounded_rect(ci, r, rad, col)
	else:
		rounded_rect(ci, Rect2(r.position + Vector2(0, lip), r.size), rad, col)
	var top := r if not pressed else Rect2(r.position + Vector2(0, lip), r.size)
	rounded_rect(ci, Rect2(top.position + Vector2(14, 8), Vector2(top.size.x - 28, top.size.y * 0.28)), rad * 0.6, Color(1, 1, 1, 0.22))


static func star_points(c: Vector2, r_out: float, r_in: float, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + rot + TAU * i / 10
		var r := r_out if i % 2 == 0 else r_in
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func star(ci: CanvasItem, c: Vector2, r: float, col: Color, rot := 0.0) -> void:
	ci.draw_colored_polygon(star_points(c, r, r * 0.48, rot), col)


## A music note (single or double).
static func note(ci: CanvasItem, p: Vector2, s: float, col: Color, double := false) -> void:
	var w := 9.0 * s / 60.0
	if double:
		ellipse(ci, p, 16 * s / 60, 12 * s / 60, col, -0.35)
		ellipse(ci, p + Vector2(40, -14) * s / 60, 16 * s / 60, 12 * s / 60, col, -0.35)
		ci.draw_line(p + Vector2(13, -3) * s / 60, p + Vector2(13, -60) * s / 60, col, w)
		ci.draw_line(p + Vector2(53, -17) * s / 60, p + Vector2(53, -74) * s / 60, col, w)
		ci.draw_line(p + Vector2(13, -60) * s / 60, p + Vector2(53, -74) * s / 60, col, w * 1.6)
	else:
		ellipse(ci, p, 16 * s / 60, 12 * s / 60, col, -0.35)
		ci.draw_line(p + Vector2(13, -3) * s / 60, p + Vector2(13, -62) * s / 60, col, w)
		var flag := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			flag.append(p + Vector2(13 + 22 * sin(t * PI * 0.9), -62 + 40 * t) * s / 60)
		ci.draw_polyline(flag, col, w * 0.9, true)


## Centered text with a thick outline, the game's title style.
static func text(ci: CanvasItem, center: Vector2, s: String, size: int, col: Color, outline := Color(0, 0, 0, 0), outline_size := 0) -> void:
	var f := font()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := center + Vector2(-w / 2, size * 0.32)
	if outline_size > 0:
		ci.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline_size, outline)
	ci.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func text_width(s: String, size: int) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Fills a polygon with a top-to-bottom gradient using vertex colours.
static func gradient_polygon(ci: CanvasItem, pts: PackedVector2Array, top: Color, bottom: Color) -> void:
	var y0 := INF
	var y1 := -INF
	for p in pts:
		y0 = min(y0, p.y)
		y1 = max(y1, p.y)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, clamp((p.y - y0) / max(1.0, y1 - y0), 0, 1)))
	ci.draw_polygon(pts, cols)


## Bubble: see-through disc with a shine.
static func bubble(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r, Color(col, 0.55))
	ci.draw_arc(c, r, 0, TAU, 40, Color(col.lightened(0.3), 0.95), max(2.0, r * 0.08), true)
	ellipse(ci, c + Vector2(-r * 0.35, -r * 0.4), r * 0.28, r * 0.16, Color(1, 1, 1, 0.8), -0.6)
	ci.draw_circle(c + Vector2(r * 0.4, r * 0.35), r * 0.07, Color(1, 1, 1, 0.6))


static func shape_points(kind: String, c: Vector2, r: float) -> PackedVector2Array:
	match kind:
		"square":
			return rounded_rect_points(Rect2(c - Vector2(r, r) * 0.86, Vector2(r, r) * 1.72), r * 0.18)
		"triangle":
			var pts := PackedVector2Array()
			for i in 3:
				var a := -PI / 2 + TAU * i / 3
				pts.append(c + Vector2(cos(a), sin(a) + 0.25) * r * 1.08)
			return pts
		"star":
			return star_points(c, r * 1.08, r * 0.5)
		"heart":
			var pts := PackedVector2Array()
			for i in 48:
				var a := TAU * i / 48
				var x := 16 * pow(sin(a), 3)
				var y := -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a))
				pts.append(c + Vector2(x, y + 2) * r / 16.5)
			return pts
	return ellipse_points(c, r, r, 40)


static func shape(ci: CanvasItem, kind: String, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(shape_points(kind, c + Vector2(0, r * 0.08), r), col.darkened(0.25))
	ci.draw_colored_polygon(shape_points(kind, c, r), col)
	ellipse(ci, c + Vector2(-r * 0.3, -r * 0.35), r * 0.22, r * 0.12, Color(1, 1, 1, 0.45), -0.6)


static func hole(ci: CanvasItem, kind: String, c: Vector2, r: float) -> void:
	ci.draw_colored_polygon(shape_points(kind, c, r * 1.06), Color(0, 0, 0, 0.32))
	ci.draw_colored_polygon(shape_points(kind, c + Vector2(0, r * 0.1), r * 0.96), Color(0, 0, 0, 0.18))


static func balloon(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var string_top := c + Vector2(0, r * 1.18)
	var pts := PackedVector2Array()
	for i in 12:
		pts.append(string_top + Vector2(sin(i * 0.9) * r * 0.08, i * r * 0.12))
	ci.draw_polyline(pts, Color(1, 1, 1, 0.9), max(2.0, r * 0.03), true)
	ci.draw_colored_polygon(ellipse_points(c, r * 0.9, r * 1.1, 40), col)
	ci.draw_colored_polygon(PackedVector2Array([string_top + Vector2(-r * 0.12, r * 0.06), string_top + Vector2(r * 0.12, r * 0.06), string_top + Vector2(0, -r * 0.1)]), col.darkened(0.15))
	ellipse(ci, c + Vector2(-r * 0.38, -r * 0.45), r * 0.18, r * 0.3, Color(1, 1, 1, 0.45), 0.4)


static func fruit(ci: CanvasItem, kind: String, c: Vector2, r: float) -> void:
	match kind:
		"apple":
			ci.draw_circle(c + Vector2(-r * 0.3, 0), r * 0.68, RED)
			ci.draw_circle(c + Vector2(r * 0.3, 0), r * 0.68, RED)
			ci.draw_circle(c + Vector2(0, r * 0.2), r * 0.7, RED)
			ci.draw_line(c + Vector2(0, -r * 0.55), c + Vector2(r * 0.08, -r * 0.95), Color("6b3e1f"), r * 0.12)
			ellipse(ci, c + Vector2(r * 0.32, -r * 0.82), r * 0.26, r * 0.12, GREEN, -0.5)
			ellipse(ci, c + Vector2(-r * 0.4, -r * 0.2), r * 0.15, r * 0.24, Color(1, 1, 1, 0.45), 0.4)
		"banana":
			var pts := PackedVector2Array()
			for i in 21:
				var a := PI * 0.15 + PI * 0.7 * i / 20.0
				pts.append(c + Vector2(cos(a) * r * 1.0, sin(a) * r * 0.9 - r * 0.45))
			for i in 21:
				var a := PI * 0.85 - PI * 0.7 * i / 20.0
				pts.append(c + Vector2(cos(a) * r * 0.85, sin(a) * r * 0.5 - r * 0.35))
			ci.draw_colored_polygon(pts, YELLOW)
			ci.draw_polyline(pts, Color("e0a800"), r * 0.06, true)
			ci.draw_circle(pts[0], r * 0.08, Color("6b3e1f"))
		"strawberry":
			var pts := PackedVector2Array([c + Vector2(-r * 0.85, -r * 0.45), c + Vector2(r * 0.85, -r * 0.45), c + Vector2(r * 0.55, r * 0.4), c + Vector2(0, r * 0.95), c + Vector2(-r * 0.55, r * 0.4)])
			ci.draw_colored_polygon(pts, Color("ff3b5c"))
			ci.draw_circle(c + Vector2(-r * 0.42, -r * 0.4), r * 0.43, Color("ff3b5c"))
			ci.draw_circle(c + Vector2(r * 0.42, -r * 0.4), r * 0.43, Color("ff3b5c"))
			for i in 7:
				ellipse(ci, c + Vector2(-r * 0.45 + (i % 4) * r * 0.3, -r * 0.2 + (i / 4) * r * 0.4 + (i % 2) * r * 0.1), r * 0.05, r * 0.08, Color("ffe27a"))
			for k in 4:
				var a := PI + PI * (k + 0.5) / 4
				ellipse(ci, c + Vector2(0, -r * 0.78) + Vector2(cos(a), sin(a) * 0.4) * r * 0.36, r * 0.24, r * 0.1, GREEN, a)
		"orange":
			ci.draw_circle(c, r * 0.85, ORANGE)
			ci.draw_circle(c + Vector2(r * 0.1, -r * 0.8), r * 0.08, Color("6b3e1f"))
			ellipse(ci, c + Vector2(r * 0.35, -r * 0.85), r * 0.25, r * 0.1, GREEN, -0.3)
			ellipse(ci, c + Vector2(-r * 0.35, -r * 0.3), r * 0.16, r * 0.24, Color(1, 1, 1, 0.4), 0.4)
		"grapes":
			for i in 6:
				var row: int = [0, 0, 0, 1, 1, 2][i]
				var col: int = [0, 1, 2, 0, 1, 0][i]
				var n: int = 3 - row
				ci.draw_circle(c + Vector2((col - (n - 1) / 2.0) * r * 0.55, -r * 0.35 + row * r * 0.48), r * 0.33, PURPLE)
				ci.draw_circle(c + Vector2((col - (n - 1) / 2.0) * r * 0.55 - r * 0.1, -r * 0.45 + row * r * 0.48), r * 0.09, Color(1, 1, 1, 0.45))
			ci.draw_line(c + Vector2(0, -r * 0.65), c + Vector2(r * 0.1, -r * 1.0), Color("6b3e1f"), r * 0.1)
			ellipse(ci, c + Vector2(r * 0.35, -r * 0.88), r * 0.24, r * 0.1, GREEN, -0.4)
