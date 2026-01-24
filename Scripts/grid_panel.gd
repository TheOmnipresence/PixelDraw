extends PanelContainer

@export var isTool = true
@export var selectable = true

var hovering = false
var wasHovering = false

func _ready() -> void:
	if not selectable:
		$Node/DescriptionContainer.position.x += 50

func _input(event: InputEvent) -> void:
	if selectable:
		if event is InputEventKey:
			if hovering and event.is_pressed():
				if (OS.get_keycode_string(event.keycode)).left(1) == str(int((OS.get_keycode_string(event.keycode)))).left(1):
					if isTool:
						Globals.barLayout[int(OS.get_keycode_string(event.keycode)) - 1] = Globals.tools.keys().find($Label.text) as Globals.tools
						Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_child(int(OS.get_keycode_string(event.keycode)) - 1).get_child(-1).text = "NONE"
						Globals.toolShapes[Globals.barLayout[int(OS.get_keycode_string(event.keycode)) - 1]] = "NONE"
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
		if event.is_action("mouse1"):
			if hovering and event.is_pressed():
				if not isTool:
					Globals.baseShape = Globals.allToolShapes[$Label.text]
					for i in Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_children():
						if i.get_child(-1).text == $Label.text:
							i.get_child(-1).text = "NONE"
							Globals.toolShapes[Globals.barLayout[Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ShapeBar").get_children().find(i)]] = "NONE"
	
	self_modulate = Color(1,1,1,1)
	if not hovering:
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
			#$Node/DescriptionContainer/MarginContainer/Label.text = ""
			$Node.visible = false
	else:
		$Node.visible = true
		if not wasHovering:
			$Node/DescriptionContainer/MarginContainer/Label.text = Globals.getDescriptionText($Label.text)
			if $Node/DescriptionContainer/MarginContainer/Label.text == "":
				$Node.visible = false
	wasHovering = hovering
	
	hovering = get_global_rect().has_point(get_global_mouse_position())
	if hovering and selectable:
		if isTool: Globals.hoveringTool = $Label.text
		else: Globals.hoveringShape = $Label.text
