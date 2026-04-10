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
	return 1.0 / (1.0 + exp(-x))

func relu(x: float) -> float:
	return max(0.0, x)

func tanh_custom(x: float) -> float:
	return tanh(x)

func softmax(input_array: Array) -> Array:
	var output = []
	var sum_exp = 0.0
	
	# Subtract max value for numeric stability
	var max_val = input_array.max()
	
	for val in input_array:
		var e_x = exp(val - max_val)
		output.append(e_x)
		sum_exp += e_x
	
	# Normalization
	for i in range(output.size()):
		output[i] /= sum_exp
		
	return output
