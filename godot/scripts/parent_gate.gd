extends Screen
## Grown-ups only: type three numbers that are written as words. Toddlers can't
## read yet, so they can't get into settings (Google Play Families policy).

const NAMES := ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"]

var arg: Variant = "parent"
var code: Array[int] = []
var typed: Array[int] = []
var _shake := 0.0


func _ready() -> void:
	_new_code()
	super._ready()


func _new_code() -> void:
	code.clear()
	typed.clear()
	while code.size() < 3:
		var n := randi_range(1, 9)
		if n not in code:
			code.append(n)


func layout() -> void:
	add_back(func() -> void: main.show_screen("home"))
	var size: float = min(150.0, (W - 160) / 3.0)
	var x0 := W / 2 - size * 1.5 - 15
	var y0 := H * 0.42
	for i in 9:
		var n := i + 1
		add_button("k%d" % n, Rect2(x0 + (i % 3) * (size + 15), y0 + int(i / 3) * (size + 15), size, size), func() -> void: _key(n))


func _key(n: int) -> void:
	typed.append(n)
	if typed.size() < code.size():
		return
	if typed == code:
		main.show_screen(str(arg))
	else:
		_shake = 1.0
		Audio.sfx("wrong")
		_new_code()


func tick(delta: float) -> void:
	_shake = max(0.0, _shake - delta * 2.5)


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("eef2f7"))
	var off := Vector2(sin(t * 50) * 14 * _shake, 0)
	Draw.text(self, Vector2(W / 2, 200), "For grown-ups", 64, Draw.INK)
	Draw.text(self, Vector2(W / 2, 290) + off, "Tap the numbers:", 40, Color("55617a"))
	var words: Array[String] = []
	for n in code:
		words.append(NAMES[n - 1])
	Draw.text(self, Vector2(W / 2, 370) + off, ",  ".join(words), 52, Draw.PINK_DARK)
	for i in 3:
		draw_circle(Vector2(W / 2 - 50 + i * 50, 440), 12, Draw.INK if i < typed.size() else Color("c9d1de"))
	for i in 9:
		var b := button("k%d" % (i + 1))
		if b.is_empty():
			continue
		var r: Rect2 = b.rect
		Draw.button_face(self, r, 30, Color.WHITE, b.down)
		Draw.text(self, r.get_center() + Vector2(0, 10 if b.down else 0), str(i + 1), 64, Draw.INK)
	draw_back()
