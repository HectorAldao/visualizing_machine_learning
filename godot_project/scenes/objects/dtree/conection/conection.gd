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

var _anim_progress : float = 0.0
var _animating : bool = false

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)

	width = line_width
	default_color = line_color

	if Engine.is_editor_hint():
		points = _calc_points(1.0)
		return

	# --- animación inicial ---
	_animating = true
	_label.modulate.a = 0.0
	points = _calc_points(0.0)

	var tween = create_tween()
	tween.tween_property(self, "_anim_progress", 1.0, 0.5)\
		 .set_trans(Tween.TRANS_LINEAR)\
		 .set_ease(Tween.EASE_IN_OUT)\
		 .connect("finished", Callable(self, "_on_anim_finished"))
	tween.parallel().tween_property(_label, "modulate:a", 1.0, 0.5)\
		 .set_trans(Tween.TRANS_LINEAR)\
		 .set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(Callable(self, "_update_from_progress"))


func _process(_delta: float) -> void:
	if _animating:
		_update_from_progress()  # actualizar cada frame mientras crece
		return
	# Mantener la línea alineada con los nodos (sin animar)
	points = _calc_points(1.0)
	_update_label()


func _calc_points(p: float) -> Array:
	
	if not (from_node and to_node):
		return []

	var from_center = from_node.global_position + (from_node.size * from_node.scale * 0.5)
	var to_center   = to_node.global_position   + (to_node.size   * to_node.scale   * 0.5)

	var from_local = to_local(from_center)
	var to_local_pos = to_local(to_center)

	# Si hay texto, la línea se corta en el medio; la animación solo afecta
	# a la distancia total entre los extremos.
	if text != "" and _label:
		var center = (from_local + to_local_pos) * 0.5
		var direction = (to_local_pos - from_local).normalized()
		var text_size = _label.get_minimum_size()
		var gap_half_width = (text_size.x / 2) + text_margin

		var corte1 = center - direction * gap_half_width
		var corte2 = center + direction * gap_half_width

		# Interpolamos cada segmento por separado
		var seg1_len = (corte1 - from_local).length()
		var seg2_len = (to_local_pos - corte2).length()
		var total_len = seg1_len + seg2_len

		# Cuánto de la longitud total queremos mostrar (p)
		var target_len = total_len * p

		# Construimos los puntos según cuánto haya avanzado la animación
		var points_arr = [from_local]

		if target_len <= seg1_len:
			# Sólo estamos dentro del primer segmento
			points_arr.append(from_local + direction * target_len)
		else:
			# Primer segmento completo + parte del segundo
			points_arr.append(corte1)
			var remaining = target_len - seg1_len
			if remaining >= seg2_len:
				# Línea completamente dibujada
				points_arr.append(corte2)
				points_arr.append(to_local_pos)
			else:
				# Creciendo dentro del segundo segmento
				points_arr.append(corte2)
				points_arr.append(corte2 + direction * remaining)

		return points_arr
	else:
		# Sin texto: línea directa
		var dir = (to_local_pos - from_local).normalized()
		var total = (to_local_pos - from_local).length()
		var target = total * p
		return [from_local, from_local + dir * target]


func _update_from_progress() -> void:
	points = _calc_points(_anim_progress)
	_update_label()


func _on_anim_finished() -> void:
	_animating = false
	points = _calc_points(1.0)
	_update_label()


func _update_label() -> void:
	if not (from_node and to_node):
		_label.visible = false
		return

	if text != "" and _label:
		var from_center = from_node.global_position + (from_node.size * from_node.scale * 0.5)
		var to_center   = to_node.global_position   + (to_node.size   * to_node.scale   * 0.5)

		var from_local = to_local(from_center)
		var to_local_pos = to_local(to_center)

		var center = (from_local + to_local_pos) * 0.5
		#var direction = (to_local_pos - from_local).normalized()
		var angle = from_local.angle_to_point(to_local_pos)

		_label.text = text
		if font:
			_label.add_theme_font_override("font", font)
		_label.add_theme_font_size_override("font_size", font_size)
		_label.add_theme_color_override("font_color", font_color)

		var text_size = _label.get_minimum_size()
		var adjusted_angle = angle
		if abs(angle) > PI / 2:
			adjusted_angle += PI

		_label.pivot_offset = text_size / 2
		_label.position = center - text_size / 2
		_label.rotation = adjusted_angle
		_label.visible = true
	else:
		_label.visible = false

func set_text(new_text: String) -> void:
	text = new_text
	queue_redraw()
