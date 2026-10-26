extends Node
## Kid-safe ads. On a phone they come from the JellyAds Android plugin (AdMob),
## which marks every request as child-directed with a G content rating, so ads
## are never personalised. Ads only appear between activities, never during play,
## and at most once every few finished activities.

## Google's test ad unit. Swap in the real one before launch.
const INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
## Show an ad once this many activities are finished since the last ad...
const EVERY := 2
## ...and never more often than this.
const MIN_GAP_SEC := 90.0

var _ads: Object
var _after := Callable()
var _last_ad := -1000.0
var _since_ad := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("JellyAds"):
		_ads = Engine.get_singleton("JellyAds")
		_ads.interstitial_closed.connect(_closed)
		_ads.start(INTERSTITIAL_ID)


## Called when a child finishes a song or game. Shows an ad if one is due,
## then calls [param done] either way.
func activity_finished(done: Callable) -> void:
	Save.finished += 1
	Save.store()
	var now := Time.get_ticks_msec() / 1000.0
	_since_ad += 1
	# If no ad is loaded yet, the next finished activity tries again.
	if _ads and _since_ad >= EVERY and now - _last_ad >= MIN_GAP_SEC and _ads.showInterstitial():
		_last_ad = now
		_since_ad = 0
		_after = done
		Audio.duck(true)
	else:
		done.call()


## For the grown-ups' corner.
func status() -> String:
	if not _ads:
		return "off (not on a phone)"
	return _ads.getStatus()


## Grown-ups' corner test button: shows an ad now if one is loaded.
func show_now(done: Callable) -> bool:
	if _ads and _ads.showInterstitial():
		_last_ad = Time.get_ticks_msec() / 1000.0
		_since_ad = 0
		_after = done
		Audio.duck(true)
		return true
	return false


func _closed() -> void:
	Audio.duck(false)
	var f := _after
	_after = Callable()
	if f.is_valid():
		f.call()
