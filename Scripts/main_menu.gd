extends Control


var devlog_link := "https://interestedsc2.itch.io/pixel-draw/devlog"


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	
	var version: String = ProjectSettings.get_setting("application/config/version")
	$VersionButton.text = get_version_prefix(version) + " " + version
	
	#var requester = HTTPRequest.new()
	#add_child(requester)
	#requester.request_completed.connect(set_devlog_link)
	#requester.request("https://interestedsc2.itch.io/pixel-draw/devlog.rss")
	
	#clear_from_pos(Vector2i(0, 0))
	
	$TileMapLayer.visible = true
	
	var list: Array[Vector2i] = []
	for x in range(128):
		for y in range(72):
			list.append(Vector2i(x, y))
	
	while not list.is_empty():
		for i in range(72):
			var random = list.pick_random()
			list.erase(random)
			$TileMapLayer.erase_cell(random)
		await get_tree().process_frame
	
	$TileMapLayer.visible = false


func clear_from_pos(pos: Vector2i) -> void:
	var list: Array[Vector2i] = [pos]
	var passed: Array[Vector2i] = []
	
	#for x in range(128):
		#for y in range(72):
			#var color_rect = ColorRect.new()
			#color_rect.color = Color.BLACK
			#color_rect.name = str(Vector2i(x, y))
			#color_rect.position = Vector2i(x, y) * 9
			#$Control.add_child(color_rect)
	
	while not list.is_empty():
		await get_tree().process_frame
		var new_list = []
		for i in list:
			#$Control.get_node(str(i)).queue_free()
			passed.append(i)
			for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
				var new_pos = i + offset
				if not passed.has(new_pos) and new_pos.x >= 0 and new_pos.y >= 0:
					new_list.append(new_pos)
		list = []
		list.assign(new_list)
	
	$TextureRect.visible = false


func set_devlog_link(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 429:
		printerr("Too many requests")
	var parser = XMLParser.new()
	if parser.open_buffer(body.get_string_from_utf8().to_utf8_buffer()) != OK:
		printerr("Can't parse")
		return
	
	var links: Array[String] = []
	
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			if parser.get_node_name() == "link":
				parser.read()
				if parser.get_node_type() == XMLParser.NODE_TEXT:
					links.append(parser.get_node_data())
	
	var adjusted = $VersionLabel.text.to_lower().replace(" ", "-").replace(".","")
	devlog_link = get_link_from_list(links, adjusted)


func get_link_from_list(list: Array[String], ending: String) -> String:
	for i in list:
		if i.contains(ending):
			return i
	return "https://interestedsc2.itch.io/pixel-draw/devlog"


func start() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().change_scene_to_file("res://Scenes/main.tscn")


func quit() -> void:
	get_tree().quit()


func send_to_discord() -> void:
	OS.shell_open("https://discord.gg/weR3Xgtaj3")


func send_to_devlog() -> void:
	OS.shell_open(devlog_link)


func get_version_prefix(version: String) -> String:
	var split = Array(version.split(".")).map(func(e): return int(e))
	if split[0] > 0:
		if split[1] == 0:
			return "Release"
		elif split[2] == 0:
			return "Update"
		else:
			return "Version"
	else:
		if split[2] == 0:
			return "Prerelease"
		else:
			return "Preversion"
