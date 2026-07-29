extends Node


var duplicate_map := Globals.DuplicateMap.new()

var last_pos: Vector2i


func _ready() -> void:
	await get_tree().process_frame
	
	var result = []
	var image: Image = $"../Background".texture.get_image()
	for x in range(image.get_size().x):
		result.append([])
		for y in range(image.get_size().y):
			result[x].append([Color.BLACK, Color.WHITE].find(image.get_pixel(x,y)))
	duplicate_map.cells.assign(result)
	
	#duplicate_map.popup_triggered.connect(func(message, color): print_rich("[color=" + color.to_html(false) + "]" + message + "[/color]"))
	duplicate_map.popup_triggered.connect(trigger_popup)


func _process(_delta: float) -> void:
	if $"../TileMapLayer".visible:
		return
	
	if Input.is_action_pressed("mouse1"):
		var current_pos = pos_to_cell(get_parent().get_global_mouse_position())
		if last_pos != current_pos:
			last_pos = current_pos
			var size = get_viewport().get_visible_rect().size
			size /= 9
			var new_image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
			for i in duplicate_map.generation_script.getShape(Vector3i(current_pos.x,0,current_pos.y),duplicate_map.base_shape):
				new_image.set_pixelv(i, Color("009eff80"))
			$"../ScanOverlay".texture = ImageTexture.create_from_image(new_image)
	else:
		$"../ScanOverlay".texture = null
		last_pos = Vector2i(-1, -1)
	if Input.is_action_just_released("mouse1"):
		duplicate_map.scan_at_pos(pos_to_cell(get_parent().get_global_mouse_position()))


func pos_to_cell(pos: Vector2) -> Vector2i:
	pos /= 9.0
	return Vector2i(floori(pos.x), floori(pos.y))


func trigger_popup(text: String, color: Color) -> void:
	var amountSame = 1
	for i in get_parent().get_node("PopupBox").get_children():
		var panelText = i.get_child(0).text
		
		if panelText == "":
			continue
		elif panelText.right(2) == "x)": 
			panelText = panelText.left(panelText.rfind("(") - 1)
			if panelText == text:
				amountSame += int(i.get_child(0).text.replace(panelText,"").left(-2).right(-2))
				i.queue_free()
				i.get_child(0).text = ""
		elif panelText == text:
			amountSame += 1
			i.queue_free()
			i.get_child(0).text = ""
	if amountSame > 1: text += " (" + str(amountSame) + "x)"
	
	var label = Label.new()
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 20
	label.label_settings.font = preload("res://Sprites/font_bigger.png")
	label.text = text
	var panel = PanelContainer.new()
	panel.modulate = color
	panel.add_child(label)
	panel.name = text
	get_parent().get_node("PopupBox").add_child(panel)
	
	Globals.allPopups.append(text)
	
	print_rich("[color=" + panel.modulate.to_html(false) + "]" + text + "[/color]")
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(panel):
		panel.queue_free()
