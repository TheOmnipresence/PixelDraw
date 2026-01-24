extends Camera3D

var availibleShapesCopy = []

var tabIndex = tabs.SETUP
enum tabs {SETUP,TOOLS,SHAPES,ACTIONS,MENU}

func _ready() -> void:
	Globals.cameraRef = self
	$HUD/SetupTab/ScannerBox/PanelContainer2.get_child(-1).text = "SCANNER"

func _process(_delta: float) -> void:
	for i in range(len(Globals.barLayout)):
		$HUD/HBoxContainer.get_child(i).get_child(-1).text = Globals.tools.keys()[Globals.barLayout[i]]
	
	for i in $HUD/HBoxContainer.get_children():
		i.get_child(0).visible = false
		i.get_child(1).visible = false
	
	$HUD/HBoxContainer.get_child(Globals.barIndex).get_child(0).visible = true
	$HUD/HBoxContainer.get_child(Globals.barIndex).get_child(1).visible = true
	
	$HUD/SetupTab/ScannerBox/PanelContainer.get_child(-1).text = Globals.allToolShapes.find_key(Globals.baseShape)
	
	var allTabs = [$HUD/SetupTab,$HUD/ToolsTab,$HUD/ShapesTab,$HUD/ActionsTab,$HUD/MenuTab]
	
	for aTab in allTabs:
		for i in aTab.get_children():
			i.visible = false
	
	$HUD/TabBar.visible = false
	if get_tree().paused:
		$HUD/TabBar.visible = true
		match tabIndex:
			tabs.SETUP:
				for i in $HUD/SetupTab.get_children():
					i.visible = true
			tabs.TOOLS:
				$HUD/SetupTab/ToolsGrid.visible = true
				for i in $HUD/ToolsTab.get_children():
					i.visible = true
			tabs.SHAPES:
				$HUD/SetupTab/ShapesBox.visible = true
				for i in $HUD/ShapesTab.get_children():
					i.visible = true
			tabs.ACTIONS:
				#$HUD/SetupTab/ActionsBox.visible = true
				for i in $HUD/ActionsTab.get_children():
					i.visible = true
			tabs.MENU:
				for i in $HUD/MenuTab.get_children():
					i.visible = true
	
	if availibleShapesCopy != Globals.availibleShapes:
		for i in $HUD/SetupTab/ShapesBox.get_children():
			i.queue_free()
		for i in Globals.availibleShapes:
			var shapePanel = preload("res://Scenes/shape_panel.tscn").instantiate()
			shapePanel.get_child(0).text = i
			$HUD/SetupTab/ShapesBox.add_child(shapePanel)
		availibleShapesCopy = Globals.availibleShapes.duplicate(true)
	
	if Input.is_action_just_pressed("mouse3") and get_tree().paused:
		var tool = Globals.tools.keys().filter(func(e): return not Globals.availibleTools.has(Globals.tools.keys().find(e)))
		if not tool.is_empty():
			tool = tool.pick_random()
			if not tool == null:
				tool = Globals.shapes[tool].pick_random()
				if not tool.is_empty():
					var maxVector = Vector2i(tool.map(func(e): return e.x).max() + 1,tool.map(func(e): return e.y).max() + 1)
					
					var image := Image.create_empty(maxVector.x,maxVector.y,false,Image.Format.FORMAT_RGBA8)
					
					for i in tool:
						image.set_pixelv(i,Color.WHITE)
						$HUD/ToolsTab/ToolFindPanel/MarginContainer/TextureRect.texture = ImageTexture.create_from_image(image)
		var shape = Globals.allToolShapes.keys().filter(func(e): return not Globals.availibleShapes.has(e))
		if not shape.is_empty():
			shape = shape.pick_random()
			if Globals.shapes.keys().has(shape):
				shape = Globals.shapes[shape].pick_random()
				if not shape.is_empty():
					var maxVector = Vector2i(shape.map(func(e): return e.x).max() + 1,shape.map(func(e): return e.y).max() + 1)
					
					var image := Image.create_empty(maxVector.x,maxVector.y,false,Image.Format.FORMAT_RGBA8)
					
					for i in shape:
						image.set_pixelv(i,Color.WHITE)
						$HUD/ShapesTab/ShapeFindPanel/MarginContainer/TextureRect.texture = ImageTexture.create_from_image(image)

func _input(event: InputEvent) -> void:
	if event.is_action("scroll_up") and event.is_released():
		Globals.barIndex -= 1
	if event.is_action("scroll_down") and event.is_released():
		Globals.barIndex += 1
	if event.is_action("plr_leave") and event.is_pressed():
		#if Globals.firstPause and len(Globals.availibleTools) > 1:
			#Globals.firstPause = false
			#$HUD/SetupTab/FirstPause1.visible = true
			#$HUD/SetupTab/FirstPause2.visible = true
		#else:
		
		$HUD/SetupTab/HelpLabels/FirstPause1.visible = false
		$HUD/SetupTab/HelpLabels/FirstPause2.visible = false
		
		get_tree().paused = not get_tree().paused
		
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Globals.barIndex <= -1: Globals.barIndex = 9
	if Globals.barIndex >= 10: Globals.barIndex = 0
	Globals.currentTool = Globals.tools.keys().find($HUD/HBoxContainer.get_child(Globals.barIndex).get_child(-1).text) as Globals.tools

func _on_tab_bar_tab_changed(tab: int) -> void:
	tabIndex = tab as tabs

func _on_end_journey_button_pressed() -> void:
	pass # Replace with function body.
