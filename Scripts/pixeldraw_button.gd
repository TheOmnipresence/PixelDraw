@tool
class_name PixeldrawButton extends TextureButton


@export var text: String:
	set(value):
		text = value
		$Label.text = text
		update_size()


func _ready() -> void:
	var og_index = z_index
	button_down.connect(func(): z_index = og_index + 1)
	button_up.connect(func(): z_index = og_index)
	
	$Label.text = text
	update_size()


func update_size() -> void:
	size.x = 9 * (1 + (len(text) * 4))
	$Background.size.x = size.x
