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
