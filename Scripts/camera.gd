extends Camera3D

var availibleShapesCopy = []

var tabIndex = tabs.SETUP
enum tabs {SETUP,TOOLS,SHAPES,ACTIONS,MENU,ARCHIPELAGO,CONSOLE,MONEY,SAVES}

var ip:String

func _enter_tree() -> void:
	Globals.cameraRef = self

func _ready() -> void:
	$HUD/SetupTab/ScannerBox/PanelContainer2.get_child(-1).text = "SCANNER"
	
	var console:Window = preload("res://godot_ap/ui/ap_console_window.tscn").instantiate()
	console.borderless = true
	console.size.y = 130
	Archipelago.load_console(console,false)
	$HUD/ArchipelagoTab/Console/Positioner.add_child(console)
	
	for i in [$HUD/ToolsTab/MarginContainer/ToolFindPanel,$HUD/ShapesTab/MarginContainer/ShapeFindPanel,$HUD/ActionsTab/MarginContainer/ActionFindPanel]:
		i.get_child(0).get_node("HBoxContainer").get_node("Copy").pressed.connect(func(): copyShape(i.get_child(0).get_node("Label").get_meta("data")))
		i.get_child(0).get_node("HBoxContainer").get_node("Pin").pressed.connect(func(): pinShape(i.get_child(0).get_node("Label").get_meta("data")))
	
	updateSaves()
	
	updateTabs()

func _process(_delta: float) -> void:
	for i in range(len(Globals.barLayout)):
		$HUD/HBoxContainer.get_child(i).get_child(-1).text = Globals.tools.keys()[Globals.barLayout[i]]
	
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
			$HUD/ActionsTab/MarginContainer/ActionFindPanel:(Globals.getActions().filter(func(e): return not Globals.actionsScanned.has(e)))
		}
		for i in hintPanelData:
			var hintRes = setRandomHint(hintPanelData[i])
			i.get_child(0).get_node("MarginContainer").get_node("TextureRect").texture = hintRes.image
			i.get_child(0).get_node("Label").text = hintRes.shape
			i.get_child(0).get_node("Label").visible = Globals.isArchipelago
			i.get_child(0).get_node("Label").set_meta(&"data",hintRes.data)
	
	if Input.is_action_just_pressed("plr_tab_up") and %TabBar.current_tab > 0:
		%TabBar.current_tab -= 1
	if Input.is_action_just_pressed("plr_tab_down") and %TabBar.current_tab + 1 < %TabBar.tab_count:
		%TabBar.current_tab += 1
	
	$HUD/MarginContainer/HBoxContainer/CompassLabel.text = {0:"N",-1:"E",-2:"S",2:"S",1:"W"}[roundi(get_parent().rotation_degrees.y/90)]

func setRandomHint(sourceList:Array,iteration:int=0) -> Dictionary:
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
				$HUD/SetupTab/ScrollContainer/ShapesBox.visible = true
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
	
	$HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/MarginContainer/TextureRect.texture = Globals.Shape.getImageFromList(shapeClass.universal_format)

func pinShape(data:String) -> void:
	palletShape = data
	
	var shapeClass = Globals.Shape.new([])
	shapeClass.binary_format = data
	$HUD/SetupTab/MarginContainer/PinPanel/VBoxContainer/MarginContainer/TextureRect.texture = Globals.Shape.getImageFromList(shapeClass.universal_format)

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
	
	if not resultPoints.is_empty():
		var typedPoints:Array[Vector2i] = []
		typedPoints.assign(resultPoints)
		$HUD/SetupTab/MinimapContainer/MinimapPanel/VBoxContainer/MarginContainer/TextureRect.texture = Globals.Shape.getImageFromList(typedPoints)
	else:
		$HUD/SetupTab/MinimapContainer/MinimapPanel/VBoxContainer/MarginContainer/TextureRect.texture = ImageTexture.new()

func _on_window_option_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
