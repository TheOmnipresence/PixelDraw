extends PanelContainer


func _ready() -> void:
	Globals.update_blueprints.connect(update)

func update() -> void:
	pass
