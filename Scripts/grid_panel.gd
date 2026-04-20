extends PanelContainer

@export var isTool = true
@export var selectable = true

var hovering = false
var wasHovering = false

func _ready() -> void:
	if not selectable:
		$Node/DescriptionContainer.position.x += 50
	#$Node/DescriptionContainer.position += global_position

func _input(event: InputEvent) -> void:
	if selectable and get_tree().paused and is_visible_in_tree():
		if hovering and event.is_pressed():
			if event is InputEventKey:
				if (OS.get_keycode_string(event.keycode)).left(1) == str(int((OS.get_keycode_string(event.keycode)))).left(1):
					if isTool:
						Globals.barLayout[int(OS.get_keycode_string(event.keycode)) - 1] = Globals.tools.keys().find($Label.text) as Globals.tools
						Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_child(int(OS.get_keycode_string(event.keycode)) - 1).get_child(-1).text = "NONE"
						Globals.toolShapes[Globals.barLayout[int(OS.get_keycode_string(event.keycode)) - 1]] = "NONE"
						
						Globals.cameraRef.updateBar()
					else:
						if Globals.toolsCompatibility[Globals.tools.keys()[(Globals.barLayout[int(OS.get_keycode_string(event.keycode)) - 1])]].has($Label.text):
							Globals.toolShapes[Globals.barLayout[int(OS.get_keycode_string(event.keycode)) - 1]] = $Label.text
							for i in Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_children():
								if i.get_child(-1).text == $Label.text:
									i.get_child(-1).text = "NONE"
									Globals.toolShapes[Globals.barLayout[Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_children().find(i)]] = "NONE"
							Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_child(int(OS.get_keycode_string(event.keycode)) - 1).get_child(-1).text = $Label.text
							if Globals.baseShape == Globals.allToolShapes[$Label.text]:
								Globals.baseShape = {}
							
							Globals.cameraRef.updateBar()
			if event.is_action("mouse1"):
				if isTool:
					@warning_ignore("static_called_on_instance")
					if not Globals.additionalCompatibilities[$Label.text].is_empty() and Globals.compatibilityChips > 0 and not len(Globals.safeGet(Globals.unlockedCompatibilities,$Label.text,[],true)) >= len(Globals.additionalCompatibilities[$Label.text]):
						Globals.compatibilityChips -= 1
						if not Globals.unlockedCompatibilities.has($Label.text):
							Globals.unlockedCompatibilities[$Label.text] = []
						var newShape = Globals.additionalCompatibilities[$Label.text].filter(func(e): return not Globals.unlockedCompatibilities[$Label.text].has(e))[0]
						Globals.toolsCompatibility[$Label.text].append(newShape)
						Globals.unlockedCompatibilities[$Label.text].append(newShape)
						%DescriptionLabel.text = Globals.getDescriptionText($Label.text)
				else:
					Globals.baseShape = Globals.allToolShapes[$Label.text]
					for i in Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_children():
						if i.get_child(-1).text == $Label.text:
							i.get_child(-1).text = "NONE"
							Globals.toolShapes[Globals.barLayout[Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_children().find(i)]] = "NONE"
			if event.is_action("mouse3"):
				if isTool:
					if Globals.isArchipelago:
						@warning_ignore("static_called_on_instance")
						Globals.compatibilityChips += len(Globals.safeGet(Globals.unlockedCompatibilities,$Label.text,[],true))
						for i in Globals.unlockedCompatibilities[$Label.text]:
							Globals.toolsCompatibility[$Label.text].erase(i)
						Globals.unlockedCompatibilities[$Label.text] = []
						%DescriptionLabel.text = Globals.getDescriptionText($Label.text)
	
	self_modulate = Color(1,1,1,1)
	if not hovering:# and not (Input.is_action_pressed("plr_ctrl") and wasHovering):
		if selectable:
			if isTool: 
				if Globals.hoveringTool == $Label.text:
					Globals.hoveringTool = "NONE"
				if Globals.hoveringShape != "NONE":
					if Globals.toolsCompatibility[$Label.text].has(Globals.hoveringShape):
						self_modulate = Color(1,0.001,0.001,1)
			else:
				if Globals.hoveringShape == $Label.text:
					Globals.hoveringShape = "NONE"
				if Globals.toolsCompatibility[Globals.hoveringTool].has($Label.text):
					self_modulate = Color(1,0.001,0.001,1)
		if wasHovering:
			#%DescriptionLabel.text = ""
			$Node.visible = false
	elif is_visible_in_tree():
		$Node.visible = true
		if not wasHovering:
			for i in $Node/DescriptionContainer/MarginContainer/VBoxContainer.get_children():
				if i != %DescriptionLabel:
					i.queue_free()
			
			for i in Globals.getComplexDescription($Label.text):
				$Node/DescriptionContainer/MarginContainer/VBoxContainer.add_child(i)
			
			%DescriptionLabel.text = Globals.getDescriptionText($Label.text)
			if %DescriptionLabel.text == "":
				$Node.visible = false
	wasHovering = hovering
	
	hovering = get_global_rect().has_point(get_global_mouse_position()) #and not Input.is_action_pressed("plr_ctrl")
	if hovering and not wasHovering:
		if selectable:
			if isTool: Globals.hoveringTool = $Label.text
			else: Globals.hoveringShape = $Label.text
		else:
			Globals.hoveringAction = $Label.text
	
	if $Node/DescriptionContainer/MarginContainer/VBoxContainer.has_node("PatternContainer"):
		if event.is_action("plr_copy") and event.is_pressed():
			$Node/DescriptionContainer/MarginContainer/VBoxContainer.get_node("PatternContainer").get_node("CopyButton").pressed.emit()
		if event.is_action("plr_pin") and event.is_pressed():
			$Node/DescriptionContainer/MarginContainer/VBoxContainer.get_node("PatternContainer").get_node("PinButton").pressed.emit()
