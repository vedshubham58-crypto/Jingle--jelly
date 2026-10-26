extends SceneTree
## Opens the app on a screen and saves screenshots.
## Args: <out prefix> <screen> [arg] ; screenshots at 1.0s and 2.5s

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var screen: String = args[1]
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var arg: Variant = args[2] if args.size() > 2 and args[2] != "-" else null
	if screen == "celebrate":
		main.show_screen("home")
		main.celebrate("home")
	else:
		main.show_screen(screen, arg)
	var times := [1.0, 2.5]
	if args.size() > 3:
		times = []
		for k in range(3, args.size()):
			times.append(float(args[k]))
	var t := 0.0
	var i := 0
	for target in times:
		while t < target:
			await process_frame
			t += 1.0 / 60.0
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png("%s_%d.png" % [out, i])
		i += 1
	quit()
