class_name Relu extends Line2D

## Rango de la función en el eje X
@export var x_range: Vector2 = Vector2(-100, 100):
	set(v):
		x_range = v
		_update_line()

## Resolución (distancia entre puntos)
@export var step: float = 1.0:
	set(v):
		step = max(0.1, v)
		_update_line()

## Escala visual para apreciar la función
@export var scale_factor: float = 1.0:
	set(v):
		scale_factor = v
		_update_line()

func _ready() -> void:
	_update_line()

func _update_line() -> void:
	var new_points = PackedVector2Array()
	
	var current_x = x_range.x
	while current_x <= x_range.y:
		var current_y = _relu(current_x)
		
		# En Godot, el eje Y positivo apunta hacia abajo. 
		# Multiplicamos por -1 si queremos que la gráfica suba visualmente.
		new_points.append(Vector2(current_x, -current_y) * scale_factor)
		
		current_x += step
		
	points = new_points

func _relu(x: float) -> float:
	return max(0.0, x)
