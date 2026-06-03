extends Control


@export var function: String = "sigmoid"  # tanh, ReLU, softmax

var zoom: Vector2 = Vector2(1.0, 1.0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## Transforms math coords to pixel coords
## because there is needed to invert the y
func math_to_canvas(math_point: Vector2) -> Vector2:
	return Vector2(math_point.x, -math_point.y)

func sigmoid(x: float) -> float:
	return Functions.sigmoid(x)

func relu(x: float) -> float:
	return Functions.relu(x)

func tanh_custom(x: float) -> float:
	return tanh(x)

func softmax(input_array: Array) -> Array:
	return Functions.apply_softmax(input_array)
