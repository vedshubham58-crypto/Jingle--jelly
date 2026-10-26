extends Screen
## Grown-ups' corner: sound settings and what the app does with data (nothing).

const VERSION := "0.2 test build"


func layout() -> void:
	add_back(func() -> void: main.show_screen("home"))
	var y := 260.0
	for id in ["sound", "music", "voice"]:
		add_button(id, Rect2(W - 220, y, 170, 84), func() -> void: _toggle(id))
		y += 120


func _toggle(id: String) -> void:
	Save.set(id, not Save.get(id))
	Save.store()
	if id == "music":
		Audio.home_music(false)


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("eef2f7"))
	Draw.text(self, Vector2(W / 2 + 30, 92), "Grown-ups' corner", 52, Draw.INK)
	var labels := {"sound": "Sound effects", "music": "Music", "voice": "Spoken help"}
	for id in labels:
		var b := button(id)
		if b.is_empty():
			continue
		var r: Rect2 = b.rect
		var f := Draw.font()
		draw_string(f, Vector2(50, r.get_center().y + 14), labels[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Draw.INK)
		var on: bool = Save.get(id)
		Draw.button_face(self, r, 42, Draw.GREEN if on else Color("b8c0cc"), b.down)
		Draw.text(self, r.get_center() + Vector2(0, 10 if b.down else 0), "ON" if on else "OFF", 40, Color.WHITE)
	var info := [
		"Jingle Jelly is made for children aged 1 to 4.",
		"",
		"It does not collect any personal information.",
		"Everything is saved only on this phone.",
		"",
		"Ads are child-safe: never personalised and G rated.",
		"They only show between activities, never during play.",
		"",
		"Songs are traditional nursery rhymes.",
		"",
		"Version " + VERSION,
	]
	var y := 680.0
	var f := Draw.font()
	for line in info:
		draw_string(f, Vector2(50, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("55617a"))
		y += 40
	draw_back()
