extends Line2D
class_name Conection

@export var from_node: Node2D
@export var to_node: Node2D

func _ready() -> void:
	# To check if the line works
	if Engine.is_editor_hint():
		_update_line()

func _process(_delta: float) -> void:
	_update_line()

func _update_line() -> void:
	if from_node and to_node:
		points = [
			to_local(from_node.global_position),
			to_local(to_node.global_position)
		]
	else:
		points = []
