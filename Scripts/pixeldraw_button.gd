@tool
class_name PixeldrawButton extends TextureButton


@export var text: String:
	set(value):
		text = value
		$Label.text = text
		update_size()

@export var pixel_size: int = 9:
	set(value):
		pixel_size = value
		update_size()


func _ready() -> void:
	var og_index = z_index
	button_down.connect(func(): z_index = og_index + 1)
	button_up.connect(func(): z_index = og_index)
	
	$Label.text = text
	update_size()


func update_size() -> void:
	size.x = pixel_size * (1 + (len(text) * 4))
	size.y = pixel_size * 6
	$Background.size = size
