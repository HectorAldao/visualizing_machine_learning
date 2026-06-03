class_name Sigmoid extends Line2D

@export var longitud_total: float = 600.0  # Ancho en píxeles
@export var amplitud: float = 200.0        # Alto en píxeles
@export var resolucion: int = 100          # Cantidad de segmentos
@export var inclinacion: float = 1.0       # Factor 'k' de la sigmoide

func _ready() -> void:
	dibujar_funcion_sigmoide()

func dibujar_funcion_sigmoide() -> void:
	clear_points()
	
	# El rango típico para visualizar la curva S de una sigmoide es de -6 a 6
	var rango_x_min: float = -6.0
	var rango_x_max: float = 6.0
	
	for i in range(resolucion + 1):
		# 1. Normalizar el progreso del bucle (0.0 a 1.0)
		var t: float = float(i) / resolucion
		
		# 2. Mapear 't' al dominio de la función (x_input)
		var x_input: float = lerp(rango_x_min, rango_x_max, t)
		
		# 3. Calcular la función Sigmoide
		var y_output: float = Functions.sigmoid(inclinacion * x_input)
		
		# 4. Transformar a coordenadas locales de Godot
		# X escala con la longitud_total
		# Y se invierte (1.0 - y_output) porque en Godot +Y apunta hacia abajo
		var x_pos: float = t * longitud_total
		var y_pos: float = (1.0 - y_output) * amplitud
		
		add_point(Vector2(x_pos, y_pos))
