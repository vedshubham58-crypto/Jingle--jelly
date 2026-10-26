extends Node
## Spoken prompts ("Pop the red bubbles!") using the phone's own text-to-speech
## voice, so toddlers who can't read still know what to do. Works offline on most
## phones; if there is no voice the game simply carries on with text.

var _voice := ""


func _ready() -> void:
	if not OS.has_feature("mobile") or not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if voices.size() > 0:
		_voice = voices[0]


func say(text: String, interrupt := true) -> void:
	if not Save.voice or _voice == "":
		return
	DisplayServer.tts_speak(text, _voice, 80, 1.15, 0.92, 0, interrupt)


func stop() -> void:
	if _voice != "":
		DisplayServer.tts_stop()
