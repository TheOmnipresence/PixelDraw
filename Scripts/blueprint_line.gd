class_name BlueprintLine extends Line2D

var origin_node: Control
var target_node: Control

func _ready() -> void:
	z_index = -30
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

func _process(_delta: float) -> void:
	clear_points()
	add_point(origin_node.global_position + Vector2(0, origin_node.size.y / 2))
	add_point(target_node.global_position + Vector2(target_node.size.x, target_node.size.y / 2))
