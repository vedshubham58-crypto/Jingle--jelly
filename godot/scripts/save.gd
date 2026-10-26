extends Node
## Saved settings and progress. Stored only on the phone; nothing is sent anywhere.

const PATH := "user://save.cfg"

var stars := 0
var sound := true
var music := true
var voice := true
var finished := 0  # activities finished, used to space out ads
var songs_played := {}  # song id -> times finished


func _ready() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	stars = c.get_value("p", "stars", 0)
	sound = c.get_value("p", "sound", true)
	music = c.get_value("p", "music", true)
	voice = c.get_value("p", "voice", true)
	finished = c.get_value("p", "finished", 0)
	songs_played = c.get_value("p", "songs_played", {})


func store() -> void:
	var c := ConfigFile.new()
	c.set_value("p", "stars", stars)
	c.set_value("p", "sound", sound)
	c.set_value("p", "music", music)
	c.set_value("p", "voice", voice)
	c.set_value("p", "finished", finished)
	c.set_value("p", "songs_played", songs_played)
	c.save(PATH)


func add_stars(n: int) -> void:
	stars += n
	store()
