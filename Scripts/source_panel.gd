extends PanelContainer


var old_text: String



func _process(_delta: float) -> void:
	if old_text != $HBoxContainer/LineEdit.text:
		if Globals.knockbacklink_sources.has(old_text):
			Globals.knockbacklink_sources.erase(old_text)
		if not Globals.knockbacklink_sources.has($HBoxContainer/LineEdit.text):
			Globals.knockbacklink_sources.append($HBoxContainer/LineEdit.text)
	old_text = $HBoxContainer/LineEdit.text


func _on_button_pressed() -> void:
	if Globals.knockbacklink_sources.has($HBoxContainer/LineEdit.text):
		Globals.knockbacklink_sources.erase($HBoxContainer/LineEdit.text)
	queue_free()
