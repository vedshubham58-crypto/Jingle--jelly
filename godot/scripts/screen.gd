class_name Screen
extends Node2D
## Base for every screen: knows the screen size, handles big tap targets
## ("buttons") and passes other touches to press/drag/release.

var main: Node
var W := 720.0
var H := 1280.0
var t := 0.0
var buttons: Array[Dictionary] = []
var _held: Dictionary = {}
var _touching := false


func _ready() -> void:
	get_viewport().size_changed.connect(_resize)
	_resize()


func _resize() -> void:
	var s := get_viewport_rect().size
	W = s.x
	H = s.y
	buttons.clear()
	layout()
	queue_redraw()


## Override: place things once the size is known (called again on resize).
func layout() -> void:
	pass


## Override: per-frame logic.
func tick(_delta: float) -> void:
	pass


## Override: touches that did not hit a button.
func press(_p: Vector2) -> void:
	pass


func drag(_p: Vector2) -> void:
	pass


func release(_p: Vector2) -> void:
	pass


func add_button(id: String, rect: Rect2, action: Callable) -> Dictionary:
	var b := {"id": id, "rect": rect, "action": action, "down": false, "enabled": true}
	buttons.append(b)
	return b


func button(id: String) -> Dictionary:
	for b in buttons:
		if b.id == id:
			return b
	return {}


func _process(delta: float) -> void:
	t += delta
	tick(delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.index != 0:
			return
		var p: Vector2 = event.position
		if event.pressed:
			_touching = true
			for i in range(buttons.size() - 1, -1, -1):
				var b := buttons[i]
				if b.enabled and b.rect.grow(12).has_point(p):
					b.down = true
					_held = b
					Audio.sfx("tap", randf_range(0.95, 1.1), -4.0)
					get_viewport().set_input_as_handled()
					return
			press(p)
		else:
			_touching = false
			if not _held.is_empty():
				var b := _held
				_held = {}
				b.down = false
				if b.rect.grow(24).has_point(p):
					b.action.call()
				get_viewport().set_input_as_handled()
				return
			release(p)
	elif event is InputEventScreenDrag:
		if event.index != 0 or not _held.is_empty():
			return
		drag(event.position)


## Shared round back button, top-left.
func add_back(action: Callable) -> void:
	add_button("back", Rect2(22, 30, 96, 96), action)


func draw_back() -> void:
	var b := button("back")
	if b.is_empty():
		return
	var r: Rect2 = b.rect
	Draw.button_face(self, r, 48, Color.WHITE, b.down)
	var c := r.get_center() + (Vector2(0, 10) if b.down else Vector2.ZERO)
	var pts := PackedVector2Array([c + Vector2(-22, 0), c + Vector2(8, -24), c + Vector2(8, -10), c + Vector2(24, -10), c + Vector2(24, 10), c + Vector2(8, 10), c + Vector2(8, 24)])
	draw_colored_polygon(pts, Draw.INK)


## Ground shadow + bounce helper: a little hop for the beat.
static func hop(time: float, bpm: float, height: float) -> float:
	var ph := fmod(time * bpm / 60.0, 1.0)
	return -abs(sin(ph * PI)) * height
