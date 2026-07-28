extends PanelContainer

var bin: String

var shape_name: String


func _ready() -> void:
	update_censor()
	#Globals.letter_scanned.connect(update_censor)
	Globals.new_action.connect(func(_action: String): update_censor())
	var shape = Globals.Shape.new([])
	shape.pattern_name_format = shape_name
	bin = shape.binary_format


func update_censor() -> void:
	$HBoxContainer/Name.text = censor_name(shape_name)


## Censors the [param current_name] with availible letters
func censor_name(current_name: String) -> String:
	var tools_has = false
	if Globals.tools.has(current_name):
		tools_has = Globals.availibleTools.has(Globals.tools[current_name])
	if (tools_has or Globals.availibleShapes.has(current_name) or Globals.actionsScanned.has(current_name)):
		return current_name
	
	var result = current_name
	for i in "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(""):
		if not Globals.actionsScanned.has("SYMBOL_" + i):
			result = result.replacen(i, "%")
	
	return result


func _on_info_pressed() -> void:
	var tools_has = false
	if Globals.tools.has(shape_name):
		tools_has = Globals.availibleTools.has(Globals.tools[shape_name])
	if (tools_has or Globals.availibleShapes.has(shape_name) or Globals.actionsScanned.has(shape_name)):
		Globals.hoveringOther = shape_name
	else:
		Globals.hoveringOther = ""


func _on_pin_pressed() -> void:
	Globals.cameraRef.pinShape(bin)


func _on_copy_pressed() -> void:
	Globals.cameraRef.copyShape(bin)
