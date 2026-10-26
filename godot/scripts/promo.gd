class_name Promo
extends CanvasLayer
## A sing-along recorded as a vertical Short or Reel for parents.
##
## Started with user arguments after "--", for example:
##   godot --path godot --write-movie clip.avi --fixed-fps 30 --resolution 720x1280 \
##     -- --promo --song=bus --seconds=22 --hook="Toddler sing-along" --cta="FREE on Google Play"
## It plays the song with its lyrics, shows the hook line at the start and an end
## card for grown-ups, then quits. tools/make_shorts.py drives it.

const OUTRO_SECONDS := 3.5

var opts := {}
var main: Node
var _clock := 0.0
var _outro_at := -1.0
var _font: Font = preload("res://fonts/Baloo2-ExtraBold.ttf")


static func wanted() -> bool:
	return "--promo" in OS.get_cmdline_user_args()


func _init(p_main: Node) -> void:
	main = p_main
	opts = {"song": "twinkle", "seconds": 22.0, "hook": "", "cta": "FREE on Google Play"}
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--") or not "=" in a:
			continue
		var k := a.substr(2, a.find("=") - 2)
		var v := a.substr(a.find("=") + 1)
		if k == "seconds":
			opts[k] = float(v)
		elif opts.has(k):
			opts[k] = v
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	main.show_screen("player", opts.song)
	if opts.hook != "":
		var l := _label(opts.hook, 54, Color.WHITE, Rect2(40, 160, 640, 190))
		_back(l, Color("ff7eb6"))
		var tw := l.create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(l, "modulate:a", 0.0, 0.4)
		tw.tween_callback(l.queue_free)


func _process(dt: float) -> void:
	_clock += dt
	if _outro_at < 0.0 and _clock >= opts.seconds:
		_outro()
	elif _outro_at >= 0.0 and _clock - _outro_at >= OUTRO_SECONDS:
		get_tree().quit()


func _label(text: String, size: int, color: Color, rect: Rect2) -> Label:
	var l := Label.new()
	# Size it before adding: a wrapping label added at zero width grows very tall.
	l.position = rect.position
	l.size = rect.size
	l.custom_minimum_size = Vector2(rect.size.x, 0)
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("3a2a6b"))
	l.add_theme_constant_override("outline_size", size / 6)
	add_child(l)
	return l


func _back(l: Label, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(40)
	s.content_margin_left = 24
	s.content_margin_right = 24
	l.add_theme_stylebox_override("normal", s)


func _outro() -> void:
	_outro_at = _clock
	var card := ColorRect.new()
	card.color = Color("fff3d6")
	card.size = Vector2(720, 1280)
	card.modulate.a = 0.0
	add_child(card)
	card.create_tween().tween_property(card, "modulate:a", 0.94, 0.4)
	var y := 330.0
	for line in [["Jingle Jelly", 96, Color("ff5fa2")], ["Nursery rhymes, bath time\nand gentle games for toddlers", 40, Color("3a2a6b")],
			["Works offline · Parent lock", 36, Color("2f9e6b")], [opts.cta, 46, Color("3aa8ff")]]:
		var h: float = line[1] * 2.6
		var l := _label(line[0], line[1], line[2], Rect2(30, y, 660, h))
		l.add_theme_color_override("font_outline_color", Color.WHITE)
		y += h + 20
		l.modulate.a = 0.0
		l.create_tween().tween_property(l, "modulate:a", 1.0, 0.4)
	Audio.sfx("yay")
