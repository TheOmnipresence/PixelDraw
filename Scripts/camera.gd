extends Camera3D


## A copy of [member Globals.availibleShapes] for setter purposes
var availibleShapesCopy = []

## The current tab
var tabIndex := tabs.SETUP

enum tabs {
	SETUP,
	TOOLS,
	SHAPES,
	ACTIONS,
	MENU,
	ARCHIPELAGO,
	CONSOLE,
	MULTIPLAYER,
	MONEY,
	SAVES,
	BLUEPRINTS,
	INFO
}

var ip: String

## The items that can be bought in a shop
var shop_items := []


func _enter_tree() -> void:
	Globals.cameraRef = self


func _ready() -> void:
	for i in [$HUD/SetupTab/ScannerBox/PanelContainer,$HUD/SetupTab/ScannerBox/PanelContainer2]:
		i.get_node("ColorRect").visible = false
		i.get_node("OutlineContainer").visible = false
	$HUD/SetupTab/ScannerBox/PanelContainer2.get_child(-1).text = "SCANNER"
	
	var console: Window = preload("res://godot_ap/ui/ap_console_window.tscn").instantiate()
	console.borderless = true
	console.size.y = 130
	#$HUD.texture_filter = texturef
	console.get_child(0).texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST
	console.get_child(0).theme = $HUD.theme.duplicate()
	console.get_child(0).theme.default_font = preload("res://Sprites/font_bigger.png")
	Archipelago.load_console(console,false)
	$HUD/ArchipelagoTab/Console/Positioner.add_child(console)
	
	for i in [$HUD/ToolsTab/MarginContainer/ToolFindPanel,$HUD/ShapesTab/MarginContainer/ShapeFindPanel,$HUD/ActionsTab/MarginContainer/VBoxContainer/ActionFindPanel]:
		i.get_child(0).get_node("HBoxContainer").get_node("Copy").pressed.connect(func(): copyShape(i.get_child(0).get_node("Label").get_meta("data")))
		i.get_child(0).get_node("HBoxContainer").get_node("Pin").pressed.connect(func(): pinShape(i.get_child(0).get_node("Label").get_meta("data")))
	
	$HUD/MarginContainer/HBoxContainer/CompassLabel.visible = false
	
	Globals.blueprints_active = false
	
	updateSaves()
	
	updateTabs()
	
	call_deferred("setup_blueprints")
	
	Globals.update_blueprints.emit()
	
	for salesman: ShopScreen in %Salesmen.get_children():
		for exchange in salesman.shop_items:
			if not exchange.first_item.is_currency:
				if not shop_items.has(exchange.first_item):
					shop_items.append(exchange.first_item)
	
	for i in Globals.shapes:
		var info_panel = preload("res://Scenes/pattern_info_panel.tscn").instantiate()
		info_panel.shape_name = i
		$HUD/DebugTab/PatternFinder/ScrollContainer/Items.add_child(info_panel)


func _process(_delta: float) -> void:
	$HUD/ArchipelagoTab/Console/Positioner.get_child(0).visible = $HUD/ArchipelagoTab/Console.visible
	
	for i in $HUD/HBoxContainer.get_children():
		i.get_child(0).visible = false
		i.get_child(1).visible = false
	
	$HUD/HBoxContainer.get_child(Globals.barIndex).get_child(0).visible = true
	$HUD/HBoxContainer.get_child(Globals.barIndex).get_child(1).visible = true
	
	$HUD/SetupTab/ScannerBox/PanelContainer.get_child(-1).text = Globals.allToolShapes.find_key(Globals.baseShape)
	
	if availibleShapesCopy != Globals.availibleShapes:
		for i in %ShapesBox.get_children():
			i.queue_free()
		for i in Globals.availibleShapes:
			var shapePanel = preload("res://Scenes/shape_panel.tscn").instantiate()
			shapePanel.get_child(0).text = i
			%ShapesBox.add_child(shapePanel)
		availibleShapesCopy = Globals.availibleShapes.duplicate(true)
	
	$HUD/ActionsTab/ScrollContainer/ActionsGrid.columns = (floor(get_viewport().get_visible_rect().size.x / (155 + 3)) - 2)
	
	if Input.is_action_just_pressed("mouse3") and get_tree().paused:
		var hintPanelData = {
			$HUD/ToolsTab/MarginContainer/ToolFindPanel:(Globals.tools.keys().filter(func(e): return (not Globals.availibleTools.has(Globals.tools.keys().find(e)) if not Globals.isArchipelago else not Globals.archipelagoLocationsFound.has(e)))),
			$HUD/ShapesTab/MarginContainer/ShapeFindPanel:(Globals.allToolShapes.keys().filter(func(e): return (not Globals.availibleShapes.has(e) if not Globals.isArchipelago else not Globals.archipelagoLocationsFound.has(e)))),
			$HUD/ActionsTab/MarginContainer/VBoxContainer/ActionFindPanel:(Globals.getActions().filter(func(e): return not Globals.actionsScanned.has(e)))
		}
		for i in hintPanelData:
			var hintRes = setRandomHint(hintPanelData[i])
			
			if Input.is_action_pressed("plr_shift"):
				if i != $HUD/ActionsTab/MarginContainer/VBoxContainer/ActionFindPanel:
					
					var iteration = 0
					
					while not Globals.pattern_in_logic(hintRes.shape):
						hintRes = setRandomHint(hintPanelData[i])
						if hintRes.shape == "200_SQR": 
							hintRes = {"image":ImageTexture.new(),"shape":"","data":""}
						iteration += 1
						if iteration >= 15:
							hintRes = {"image":ImageTexture.new(),"shape":"","data":""}
							break
			
			i.get_child(0).get_node("MarginContainer").get_node("TextureRect").texture = hintRes.image
			i.get_child(0).get_node("Label").text = hintRes.shape
			i.get_child(0).get_node("Label").visible = Globals.isArchipelago
			i.get_child(0).get_node("Label").set_meta(&"data",hintRes.data)
	
	if Input.is_action_just_pressed("plr_tab_up") and %TabBar.current_tab > 0:
		%TabBar.current_tab -= 1
	if Input.is_action_just_pressed("plr_tab_down") and %TabBar.current_tab + 1 < %TabBar.tab_count:
		%TabBar.current_tab += 1
	
	if not get_tree().paused:
		if Input.is_action_just_pressed("plr_copy"):
			_on_minimap_copy_pressed()
		if Input.is_action_just_pressed("plr_pin"):
			_on_minimap_pin_pressed()
	
	$HUD/MarginContainer/HBoxContainer/CompassLabel.text = {0:"N",-1:"E",-2:"S",2:"S",1:"W"}[roundi(get_parent().rotation_degrees.y/90)]


## Returns a random hint dictionary from [param sourceList]
func setRandomHint(sourceList: Array, iteration: int = 0) -> Dictionary:
	if iteration >= 30: return {"image":ImageTexture.new(),"shape":"","data":""}
	if not sourceList.is_empty():
		var shape = sourceList.pick_random()
		if Globals.shapes.keys().has(shape):
			var shapePoints:Array[Vector2i] = []
			var untypedPoints = Globals.shapes[shape].pick_random()
			shapePoints.assign(untypedPoints)
			if not shapePoints.is_empty():
				return {"image":Globals.Shape.getImageFromList(shapePoints),"shape":shape,"data":Globals.Shape.shapeToBinary(shapePoints)}
		else:
			sourceList.erase(shape)
	else:
		return {"image":ImageTexture.new(),"shape":"","data":""}
	return setRandomHint(sourceList,iteration + 1)


## Updates visibility of items on the tabs
func updateTabs() -> void:
	var allTabs = get_child(0).get_children().filter(func(e): return str(e.name).contains("Tab") and not str(e.name) == "TabBar")
	#allTabs = [$HUD/SetupTab,$HUD/ToolsTab,$HUD/ShapesTab,$HUD/ActionsTab,$HUD/MenuTab,$HUD/ArchipelagoTab,$HUD/ConsoleTab,$HUD/MultiplayerTab,$HUD/MoneyTab]
	for aTab in allTabs:
		for i in aTab.get_children():
			i.visible = false
	
	%TabBar.visible = false
	if get_tree().paused:
		%TabBar.visible = true
		for i in allTabs[tabIndex].get_children():
			i.visible = true
		match tabIndex:
			tabs.TOOLS:
				$HUD/SetupTab/ToolsGrid.visible = true
				for i in $HUD/ToolsTab.get_children():
					i.visible = true
			tabs.SHAPES:
				$HUD/SetupTab/ScrollContainer.visible = true
				for i in $HUD/ShapesTab.get_children():
					i.visible = true
			tabs.ACTIONS:
				#$HUD/SetupTab/ActionsBox.visible = true
				for i in $HUD/ActionsTab.get_children():
					i.visible = true
			tabs.MONEY:
				for i in $HUD/MoneyTab.get_children():
					i.visible = true
	
	$HUD/SetupTab/MarginContainer.visible = ($HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/PalletOptions/Button.text == "Hide" and not get_tree().paused) or (get_tree().paused and (%TabBar.current_tab as tabs == tabs.SETUP))
	$HUD/SetupTab/MinimapContainer.visible = ($HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/MinimapOptions/MinimapToggle.text == "Hide Minimap") and not get_tree().paused
	
	$HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/PalletOptions.visible = get_tree().paused
	$HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/MinimapOptions.visible = get_tree().paused


func updateSaves() -> void:
	for i in $HUD/SavesTab/MarginContainer/VBoxContainer.get_children(): i.queue_free()
	
	for i in Array(DirAccess.open("user://Data/").get_files()).filter(func(e): return str(e).contains("save")):
		var time = (Time.get_datetime_dict_from_unix_time(FileAccess.get_access_time("user://Data/"+i)))
		var pairBox := HBoxContainer.new()
		
		var saveButton := Button.new()
		var saveIndex := str(i).replace("save","").replace(".dat","")
		saveButton.text = "Save"
		saveButton.pressed.connect(func():Globals.saveSlot(int(saveIndex)))
		pairBox.add_child(saveButton)
		
		var loadButton := Button.new()
		var loadIndex := str(i).replace("save","").replace(".dat","")
		loadButton.text = "Load"
		loadButton.pressed.connect(func():Globals.loadSlot(int(loadIndex)))
		pairBox.add_child(loadButton)
		
		var nameLabel := Label.new()
		nameLabel.text = "Slot " + saveIndex + ", " + str(time.month) + "/" + str(time.day) + "/" + str(time.year - 2000)
		pairBox.add_child(nameLabel)
		
		$HUD/SavesTab/MarginContainer/VBoxContainer.add_child(pairBox)
	
	var saveAsNewButton := Button.new()
	saveAsNewButton.text = "Save as new slot"
	saveAsNewButton.pressed.connect(func(): Globals.saveSlot(-1))
	$HUD/SavesTab/MarginContainer/VBoxContainer.add_child(saveAsNewButton)


func _input(event: InputEvent) -> void:
	if event.is_action("scroll_up") and event.is_released():
		Globals.barIndex -= 1
		updateBar()
	if event.is_action("scroll_down") and event.is_released():
		Globals.barIndex += 1
		updateBar()
	if event.is_action("plr_leave") and event.is_pressed():
		
		get_tree().paused = not get_tree().paused
		
		updateTabs()
		
		if get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
			if tabIndex == tabs.CONSOLE:
				var lineEdit = $HUD/ConsoleTab/VBoxContainer/LineEdit
				lineEdit.grab_focus()
				lineEdit.caret_column = lineEdit.text.length()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
			get_parent().get_parent().get_node("GridMapOutline").clear()
	
	if event is InputEventMouseButton and not get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Globals.isMultiplayer:
		if event.is_action_pressed("mouse1"): checkForIp()
		elif event.is_action_released("mouse1"): $HUD/MultiplayerTab/MarginContainer/PanelContainer/VBoxContainer/IPLabel.text = "Click to reveal IP"


func checkForIp():
	await get_tree().process_frame
	if get_viewport().gui_get_focus_owner() == $HUD/MultiplayerTab/MarginContainer/PanelContainer/VBoxContainer/IPLabel:
		$HUD/MultiplayerTab/MarginContainer/PanelContainer/VBoxContainer/IPLabel.text = ip


func updateBar():
	for i in range(len(Globals.barLayout)):
		var shape = Globals.tools.keys()[Globals.barLayout[i]]
		$HUD/HBoxContainer.get_child(i).get_child(-1).text = shape
		var shapeRes = Globals.Shape.new([])
		shapeRes.pattern_name_format = shape
		$HUD/HBoxContainer.get_child(i).get_node("TextureContainer").get_child(0).texture = shapeRes.icon_format
	if Globals.barIndex <= -1: Globals.barIndex = 9
	if Globals.barIndex >= 10: Globals.barIndex = 0
	Globals.currentTool = Globals.tools.keys().find($HUD/HBoxContainer.get_child(Globals.barIndex).get_child(-1).text) as Globals.tools


func _on_tab_bar_tab_changed(tab: int) -> void:
	tabIndex = tab as tabs
	updateTabs()


func _on_end_journey_button_pressed() -> void:
	pass


func hostMultiplayer() -> void:
	ip = MultiplayerSetup.host()


func joinMultiplayer(text=$HUD/MultiplayerTab/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/Code.text) -> void:
	multiplayer.connected_to_server.connect(func():Globals.gridRef.rpc_id(1,"sendMap"))
	MultiplayerSetup.join(text)


var palletShape = ""

var internalClipboard = ""


func _on_pallet_button_pressed() -> void:
	var button = $HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/PalletOptions/Button
	button.text = {"Show":"Hide","Hide":"Show"}[button.text]


func _on_copy_pressed() -> void:
	#DisplayServer.clipboard_set(Globals.Shape.binaryToHex(palletShape))
	DisplayServer.clipboard_set(Globals.Shape.binaryToHex(palletShape) if Input.is_action_pressed("plr_shift") else palletShape)
	internalClipboard = palletShape


func _on_paste_pressed() -> void:
	pinShape(DisplayServer.clipboard_get())


func _on_clockwise_pressed() -> void:
	rotateShape()


func _on_counterclockwise_pressed() -> void:
	rotateShape(false)


func rotateShape(clockwise:=true) -> void:
	var shapeClass = Globals.Shape.new([])
	shapeClass.binary_format = palletShape
	shapeClass.universal_format = Globals.Shape.rotatePoints(shapeClass.universal_format,clockwise)
	palletShape = shapeClass.binary_format
	
	$HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/MarginContainer/TextureRect.texture = shapeClass.image_format


func pinShape(data:String) -> void:
	palletShape = data
	
	var shapeClass = Globals.Shape.new([])
	shapeClass.binary_format = data
	$HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/MarginContainer/TextureRect.texture = shapeClass.image_format
	#get_parent().get_parent().get_node("test").get_child(0).mesh.surface_get_material(0).albedo_texture = shapeClass.icon_format


func copyShape(data:String) -> void:
	DisplayServer.clipboard_set(Globals.Shape.binaryToHex(data) if Input.is_action_pressed("plr_shift") else data)


func _on_minimap_toggle_pressed() -> void:
	var button = $HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/MinimapOptions/MinimapToggle
	button.text = {"Show Minimap":"Hide Minimap","Hide Minimap":"Show Minimap"}[button.text]
	
	if button.text == "Hide Minimap":
		updateMinimap(Vector2i(roundi(get_parent().position.x),roundi(get_parent().position.z)))


func _on_minimap_smaller_pressed() -> void:
	minimapRadius -= 1


func _on_minimap_bigger_pressed() -> void:
	minimapRadius += 1


var minimapRadius = 2:
	set(value):
		minimapRadius = clampi(value,0,10)
		updateMinimap(Vector2i(roundi(get_parent().position.x),roundi(get_parent().position.z)))


func updateMinimap(playerPos:Vector2i) -> void:
	var positionsToCheck = []
	var resultPoints = []
	for x in range((2 * minimapRadius) + 1):
		for y in range((2 * minimapRadius) + 1):
			positionsToCheck.append(Vector2i(x,y))
	
	for i in positionsToCheck:
		var cellItem = Globals.gridRef.get_cell_item(Globals.gridRef.vector2to3((i-Vector2i(minimapRadius,minimapRadius))+playerPos,0))
		if cellItem == 1:
			resultPoints.append(i)
	
	var shape = Globals.Shape.new([])
	
	if not resultPoints.is_empty():
		var typedPoints:Array[Vector2i] = []
		typedPoints.assign(resultPoints)
		shape.universal_format = typedPoints
		$HUD/SetupTab/MinimapContainer/MinimapPanel.set_meta("data",shape.hexadecimal_format)
		$HUD/SetupTab/MinimapContainer/MinimapPanel/VBoxContainer/MarginContainer/TextureRect.texture = shape.image_format
	else:
		$HUD/SetupTab/MinimapContainer/MinimapPanel.set_meta("data","")
		$HUD/SetupTab/MinimapContainer/MinimapPanel/VBoxContainer/MarginContainer/TextureRect.texture = ImageTexture.new()


func _on_window_option_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func updateDescriptionWindows(type:String,value:String) -> void:
	var node = {
		"Tool":null,
		"Shape":null,
		"Action":$HUD/ActionsTab/MarginContainer/VBoxContainer/Panel/Label,
	}[type]
	if node == null: return
	
	set_full_pattern_description(value, node, node.get_parent().get_parent())


func updateSearchWindow(value: String) -> void:
	set_full_pattern_description(value, get_child(0).get_node("DebugTab").get_node("PatternInfo/Container/Label"), get_child(0).get_node("DebugTab").get_node("PatternInfo/Container"))


func set_full_pattern_description(value: String, label: Label, parent: Control) -> void:
	label.text = Globals.getDescriptionText(value)
	for i in parent.get_children().filter(func(e): return not e == label and not e is PanelContainer):
		i.queue_free()
	for i in Globals.getComplexDescription(value):
		if i is TextureRect:
			i.size_flags_horizontal = Control.SIZE_SHRINK_END
		elif i is HBoxContainer:
			for button in i.get_children():
				if button is Button:
					button.text = button.text.split("\n")[0]
		parent.add_child(i)


func _on_minimap_copy_pressed() -> void:
	copyShape($HUD/SetupTab/MinimapContainer/MinimapPanel.get_meta("data"))


func _on_minimap_pin_pressed() -> void:
	pinShape($HUD/SetupTab/MinimapContainer/MinimapPanel.get_meta("data"))


func setup_blueprints() -> void:
	var arrangement = Globals.BluePrint.arrange_blueprints(Globals.ALL_BLUEPRINTS)
	var pattern_to_node: Dictionary[String,PanelContainer]
	
	for column_contents in arrangement:
		var box = VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.custom_minimum_size = Vector2(250,300)
		box.add_theme_constant_override("separation", 50)
		for blueprint in column_contents:
			var panel: PanelContainer = preload("res://Scenes/blueprint_panel.tscn").instantiate()
			panel.name = blueprint.target_pattern
			var update_amounts = (func():
				var amount = blueprint.current_amount.call()
				if amount == 0 and blueprint.needed_amount == 0 and blueprint.units == "":
					panel.get_child(0).get_node("Label").text = "Get previous to unlock"
				else:
					panel.get_child(0).get_node("Label").text = str(amount) + "/" + str(blueprint.needed_amount) + " " + blueprint.units
				panel.get_child(0).get_node("Bar").value = amount
				panel.get_child(0).get_node("Bar").max_value = blueprint.needed_amount
				
				var is_ap_item = Globals.isArchipelago
				if is_ap_item: 
					if not Archipelago.conn.slot_data.is_empty():
						is_ap_item = Archipelago.conn.slot_data["randomize_blueprints"]
				#if is_ap_item: is_ap_item = not Globals.getActions().has(blueprint.target_pattern)
				if is_ap_item and panel.get_child(0).get_node("Pattern").text.left(4) != "Arch":
					panel.get_child(0).get_node("Pattern").visible = true
					print(Globals.BLUEPRINT_SHAPES.find(blueprint.target_pattern) + 5001)
					Archipelago.conn.scout(Globals.BLUEPRINT_SHAPES.find(blueprint.target_pattern) + 5001, 2, 
					func(e): ShopScreen.set_archipelago_item_name(e, panel.get_child(0).get_node("Pattern"))
					)
				
				if Globals.blueprints_active:
					@warning_ignore("static_called_on_instance")
					if amount >= blueprint.needed_amount and not Globals.blueprints_achieved.has(blueprint) and blueprint.has_met_requirements():
						Globals.blueprints_achieved.append(blueprint)
						Globals.gridRef.runShape("BLUEPRINT_" + blueprint.target_pattern)
						panel.get_child(0).get_node("Buttons/PinButton").visible = true
						panel.get_child(0).get_node("Buttons/CopyButton").visible = true
						panel.get_child(0).get_node("Pattern").visible = true
						panel.modulate = Color(0.2,0.2,0.2,1)
				)
			
			var typed: Array[Vector2i] = []
			typed.assign(Globals.shapes[blueprint.target_pattern][0])
			var shape_res = Globals.Shape.new(typed)
			
			update_amounts.call()
			Globals.update_blueprints.connect(update_amounts)
			panel.get_child(0).get_node("Buttons/PinButton").visible = false
			panel.get_child(0).get_node("Buttons/CopyButton").visible = false
			panel.get_child(0).get_node("Pattern").visible = false
			panel.get_child(0).get_node("Pattern").text = "Unlocked " + blueprint.target_pattern
			panel.get_child(0).get_node("Buttons/PinButton").pressed.connect(pinShape.bind(shape_res.binary_format))
			panel.get_child(0).get_node("Buttons/CopyButton").pressed.connect(copyShape.bind(shape_res.hexadecimal_format))
			
			box.add_child(panel)
			
			pattern_to_node[blueprint.target_pattern] = panel
			for i in blueprint.requirements:
				var line = BlueprintLine.new()
				line.origin_node = panel
				line.target_node = pattern_to_node[i]
				get_node("HUD/BlueprintsTab").add_child(line)
		$HUD/BlueprintsTab/ScrollContainer/HBoxContainer.add_child(box)
		var spacer = Control.new()
		spacer.custom_minimum_size.x = 100
		$HUD/BlueprintsTab/ScrollContainer/HBoxContainer.add_child(spacer)
		#box.queue_sort()
	
	#$HUD/BlueprintsTab/ScrollContainer/HBoxContainer.queue_sort()

func setBlueprintVisibility(disabled: bool) -> void:
	if Globals.isArchipelago:
		disabled = false
	for i in range(%TabBar.tab_count):
		if %TabBar.get_tab_title(i) == "Blueprints":
			%TabBar.set_tab_disabled(i, disabled)


func update_search() -> void:
	var new_text = $HUD/DebugTab/PatternFinder/SearchBar.text
	var pattern_size = $HUD/DebugTab/PatternFinder/HBoxContainer/SizeLine.text.to_int()
	var type_option = $HUD/DebugTab/PatternFinder/HBoxContainer/TypeOption.selected
	var discovered_option = $HUD/DebugTab/PatternFinder/HBoxContainer/DiscoveredOption.selected
	
	for i in $HUD/DebugTab/PatternFinder/ScrollContainer/Items.get_children():
		i.visible = true
		var current_text = i.shape_name
		
		if not (current_text.containsn(new_text.replace(" ","_")) or new_text == ""):
			i.visible = false
		
		match type_option:
			0:
				pass
			1:
				if not Globals.tools.has(current_text):
					i.visible = false
			2:
				if not Globals.allToolShapes.has(current_text):
					i.visible = false
			3:
				if not Globals.getActions().has(current_text):
					i.visible = false
		
		match discovered_option:
			0:
				pass
			1:
				var tools_has = false
				if Globals.tools.has(current_text):
					tools_has = Globals.availibleTools.has(Globals.tools[current_text])
				if not (tools_has or Globals.availibleShapes.has(current_text) or Globals.actionsScanned.has(current_text)):
					i.visible = false
			2:
				var tools_has = false
				if Globals.tools.has(current_text):
					tools_has = Globals.availibleTools.has(Globals.tools[current_text])
				if (tools_has or Globals.availibleShapes.has(current_text) or Globals.actionsScanned.has(current_text)):
					i.visible = false
		
		if pattern_size > 0:
			var size_text: String = $HUD/DebugTab/PatternFinder/HBoxContainer/SizeLine.text
			var current_size = Globals.Shape.max_size(Globals.shapes[current_text][0])
			current_size += 1
			
			if not size_text.get_slice(" ", 0).is_valid_int():
				match size_text.get_slice(" ", 0):
					"=":
						if current_size != pattern_size:
							i.visible = false
					"==":
						if current_size != pattern_size:
							i.visible = false
					">":
						if not current_size > pattern_size:
							i.visible = false
					"<":
						if not current_size < pattern_size:
							i.visible = false
					">=":
						if not current_size >= pattern_size:
							i.visible = false
					"<=":
						if not current_size <= pattern_size:
							i.visible = false
					"!=":
						if current_size == pattern_size:
							i.visible = false
			elif current_size != pattern_size:
				i.visible = false


func _on_search_bar_text_changed(_new_text: String) -> void:
	update_search()


func _on_size_line_text_changed(_new_text: String) -> void:
	update_search()


func _on_type_option_item_selected(_index: int) -> void:
	update_search()


func _on_discovered_option_item_selected(_index: int) -> void:
	update_search()
