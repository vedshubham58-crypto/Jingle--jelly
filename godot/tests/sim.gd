extends SceneTree
## Headless checks run by CI: every screen opens, songs line up with their
## audio, and each game can be finished the way a child would play it.

var failures := 0


func check(ok: bool, what: String) -> void:
	if ok:
		print("ok   ", what)
	else:
		failures += 1
		printerr("FAIL ", what)


func frames(n: int) -> void:
	for i in n:
		await process_frame


## Waits (real time) until [param ok] returns true; false if it never does.
func wait_until(ok: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end:
		if ok.call():
			return true
		await process_frame
	return false


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(2)

	for name in main.SCREENS:
		var s = main.show_screen(name)
		await frames(3)
		check(is_instance_valid(s) and s.is_inside_tree(), "screen %s opens" % name)

	# Songs: words are in order and fit inside the rendered audio.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/songs.json"))
	for song in data.songs:
		var p = main.show_screen("player", song.id)
		await frames(2)
		check(p.words.size() > 10, "%s has words" % song.id)
		var ordered := true
		for i in range(1, p.words.size()):
			ordered = ordered and p.words[i].start > p.words[i - 1].start
		check(ordered, "%s words in time order" % song.id)
		var stream: AudioStream = load("res://audio/song_%s.ogg" % song.id)
		check(stream != null and p.words[-1].end < stream.get_length(), "%s audio covers every word" % song.id)
		check(p.word_at(0.0) == -1 and p.word_at(p.words[3].start + 0.01) == 3, "%s lights the right word" % song.id)
		root.get_node("Audio").stop_song()

	# Bath: scrub every spot, then rinse.
	var bath = main.show_screen("bath")
	await frames(2)
	for st in bath.STEPS:
		for spot in st.spots:
			var c: Vector2 = bath.spot_pos(spot)
			bath.press(c)
			for k in 60:
				bath.drag(c + Vector2(40 if k % 2 == 0 else -40, 0))
			bath.release(c)
	check(bath.step == bath.STEPS.size(), "bath: all parts washed")
	bath.press(bath._shower_rect().get_center())
	check(bath.rinsing > 0, "bath: shower rinses")
	var stars_before: int = root.get_node("Save").stars
	await wait_until(func() -> bool: return root.get_node("Save").stars > stars_before, 5.0)
	check(root.get_node("Save").stars == stars_before + 1, "bath: finishing gives a star")
	check(await wait_until(func() -> bool: return main.current_name == "games", 6.0), "bath: back to games after the celebration")

	# Bubbles: pop the right colour every round.
	var bub = main.show_screen("bubbles")
	await frames(2)
	var give_up := Time.get_ticks_msec() + 90000
	while not bub._finished and Time.get_ticks_msec() < give_up:
		await process_frame
		for b in bub.bubbles:
			if b.col == bub.target() and b.p.y < bub.H - 40 and bub._between <= 0:
				bub.press(b.p)
				break
	check(bub._finished, "bubbles: all rounds finished")
	check(await wait_until(func() -> bool: return main.current_name == "games", 6.0), "bubbles: back to games after the celebration")

	# Shapes: a wrong hole bounces back, the right holes finish every round.
	var sh = main.show_screen("shapes")
	await frames(2)
	var wrong_hole: Vector2 = sh.holes.filter(func(h: Dictionary) -> bool: return h.kind != sh.pieces[0].kind)[0].p
	sh.drop(0, wrong_hole)
	check(not sh.pieces[0].placed, "shapes: wrong hole does not take the shape")
	give_up = Time.get_ticks_msec() + 30000
	while not sh._finished and Time.get_ticks_msec() < give_up:
		await process_frame
		if sh._between > 0:
			continue
		for i in sh.pieces.size():
			if not sh.pieces[i].placed:
				var kind: String = sh.pieces[i].kind
				sh.drop(i, sh.holes.filter(func(h: Dictionary) -> bool: return h.kind == kind)[0].p)
				break
	check(sh._finished, "shapes: all rounds finished")
	check(await wait_until(func() -> bool: return main.current_name == "games", 6.0), "shapes: back to games after the celebration")

	# Feed Jelly: the wrong fruit is refused, the right ones are counted.
	var fd = main.show_screen("feed")
	await frames(2)
	for i in fd.fruits.size():
		if fd.fruits[i].kind != fd.target():
			fd.feed(i)
			break
	check(fd.eaten == 0, "feed: wrong fruit is refused")
	give_up = Time.get_ticks_msec() + 30000
	while not fd._finished and Time.get_ticks_msec() < give_up:
		await process_frame
		if fd._between > 0:
			continue
		for i in fd.fruits.size():
			if not fd.fruits[i].eaten and fd.fruits[i].kind == fd.target():
				fd.feed(i)
				break
	check(fd._finished, "feed: all rounds finished")
	check(await wait_until(func() -> bool: return main.current_name == "games", 6.0), "feed: back to games after the celebration")

	# Balloon ABC: pop the target letter every round.
	var bal = main.show_screen("balloons")
	await frames(2)
	give_up = Time.get_ticks_msec() + 120000
	while not bal._finished and Time.get_ticks_msec() < give_up:
		await process_frame
		for b in bal.balloons:
			if b.letter == bal.target() and b.p.y < bal.H - 40 and bal._between <= 0:
				bal.press(b.p)
				break
	check(bal._finished, "balloons: all rounds finished")
	check(await wait_until(func() -> bool: return main.current_name == "games", 6.0), "balloons: back to games after the celebration")

	# Parent gate: wrong code resets, right code opens grown-ups' corner.
	var gate = main.show_screen("gate")
	await frames(2)
	var wrong: Array[int] = []
	for n in range(1, 10):
		if n not in gate.code and wrong.size() < 3:
			wrong.append(n)
	for n in wrong:
		gate._key(n)
	check(main.current_name == "gate" and gate.typed.is_empty(), "gate: wrong code stays locked")
	for n in gate.code.duplicate():
		gate._key(n)
	await frames(2)
	check(main.current_name == "parent", "gate: right code opens grown-ups' corner")

	print("%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
