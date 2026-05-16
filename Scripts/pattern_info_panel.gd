extends PanelContainer

var bin: String


func _ready() -> void:
	var shape = Globals.Shape.new([])
	shape.pattern_name_format = $HBoxContainer/Name.text
	bin = shape.binary_format


func _on_info_pressed() -> void:
	Globals.hoveringOther = $HBoxContainer/Name.text


func _on_pin_pressed() -> void:
	Globals.cameraRef.pinShape(bin)


func _on_copy_pressed() -> void:
	Globals.cameraRef.copyShape(bin)
