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
