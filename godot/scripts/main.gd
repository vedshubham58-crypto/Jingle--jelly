extends Node
## Switches between screens. Each screen is a Screen node built in code.

const SCREENS := {
	"home": "res://scripts/home.gd",
	"songs": "res://scripts/songs.gd",
	"player": "res://scripts/song_player.gd",
	"bath": "res://scripts/bath.gd",
	"games": "res://scripts/games.gd",
	"bubbles": "res://scripts/bubbles.gd",
	"shapes": "res://scripts/shapes.gd",
	"feed": "res://scripts/feed.gd",
	"balloons": "res://scripts/balloons.gd",
	"gate": "res://scripts/parent_gate.gd",
	"parent": "res://scripts/parent.gd",
}

var current: Screen
var current_name := ""


func _ready() -> void:
	randomize()
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	show_screen("home")


func show_screen(name: String, arg: Variant = null) -> Screen:
	if current:
		current.queue_free()
	Voice.stop()
	var s: Screen = load(SCREENS[name]).new()
	s.main = self
	if arg != null:
		s.set("arg", arg)
	add_child(s)
	current = s
	current_name = name
	Audio.home_music(name in ["home", "songs", "games"])
	s.modulate.a = 0.0
	create_tween().tween_property(s, "modulate:a", 1.0, 0.18)
	return s


## Shows the celebration on top of the current screen, gives a star, then
## (maybe) an ad, then goes to [param next].
func celebrate(next: String, stars := 1) -> void:
	var c := Celebrate.new()
	c.stars = stars
	c.done = func() -> void:
		Ads.activity_finished(func() -> void: show_screen(next))
	add_child(c)
	Save.add_stars(stars)


func _notification(what: int) -> void:
	# Android back button: go up one level, never leave the app by accident.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		match current_name:
			"home":
				if what == NOTIFICATION_WM_CLOSE_REQUEST:
					get_tree().quit()
			"player":
				show_screen("songs")
			"bath", "bubbles", "shapes", "feed", "balloons":
				show_screen("games")
			_:
				show_screen("home")
