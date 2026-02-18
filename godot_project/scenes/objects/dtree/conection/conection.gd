extends Line2D
class_name Conection

@export var from_node: Control
@export var to_node: Control
@export var text: String = ""
@export var font: Font
@export var font_size: int = 16
@export var font_color: Color = Color.WHITE
@export var text_margin: float = 10.0
@export var line_width: float = 2.0
@export var line_color: Color = Color.BLACK

var _label: Label

func _ready() -> void:
	# Crear el Label para el texto
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)
	
	# Configurar grosor y color de la línea
	width = line_width
	default_color = line_color
	
	# To check if the line works
	if Engine.is_editor_hint():
		_update_line()

func _process(_delta: float) -> void:
	_update_line()

func _update_line() -> void:
	if from_node and to_node:
		# Calculate center positions of the nodes, accounting for scale
		var from_center = from_node.global_position + (from_node.size * from_node.scale * 0.5)
		var to_center = to_node.global_position + (to_node.size * to_node.scale * 0.5)
		
		var from_local = to_local(from_center)
		var to_local_pos = to_local(to_center)
		
		# Si hay texto, dividir la línea en dos segmentos
		if text != "" and _label:
			var center = (from_local + to_local_pos) / 2
			var direction = (to_local_pos - from_local).normalized()
			var angle = from_local.angle_to_point(to_local_pos)
			
			# Configurar el label
			_label.text = text
			if font:
				_label.add_theme_font_override("font", font)
			_label.add_theme_font_size_override("font_size", font_size)
			_label.add_theme_color_override("font_color", font_color)
			
			# Calcular el tamaño del texto
			var text_size = _label.get_minimum_size()
			var gap_half_width = (text_size.x / 2) + text_margin
			
			# Puntos donde la línea se interrumpe
			var punto_corte_1 = center - direction * gap_half_width
			var punto_corte_2 = center + direction * gap_half_width
			
			# Dibujar los dos segmentos de línea
			points = [
				from_local,
				punto_corte_1,
				punto_corte_2,
				to_local_pos
			]
			
			# Corregir la rotación si el texto queda al revés
			# Si el ángulo está fuera del rango [-π/2, π/2], voltear el texto
			var adjusted_angle = angle
			if abs(angle) > PI / 2:
				adjusted_angle += PI
			
			# Establecer el pivot en el centro del texto para que rote sobre su centro
			_label.pivot_offset = text_size / 2
			
			# Posicionar el label en el centro de la conexión
			_label.position = center - text_size / 2
			_label.rotation = adjusted_angle
			_label.visible = true
		else:
			# Sin texto, dibujar línea completa
			points = [
				from_local,
				to_local_pos
			]
			if _label:
				_label.visible = false
	else:
		points = []
		if _label:
			_label.visible = false

func set_text(new_text: String) -> void:
	text = new_text
	queue_redraw()
