class_name Conection extends Line2D
const scene_uid: String = Constants.SCENES.conection

@export var from_node: Control
@export var to_node: Control
@export var text: String = ""
@export var font: Font = ThemeDB.fallback_font
@export var font_size: int = 16
@export var font_color: Color = Color.WHITE
@export var text_margin: float = 10.0
@export var line_width: float = 2.0
@export var line_color: Color = Color.BLACK
@export var positive_update_indicator_color: Color = Color.GREEN
@export var negative_update_indicator_color: Color = Color.RED
@export var neutral_update_indicator_color: Color = Color.WHITE

var _label: Label

var _anim_progress : float = 0.0
var _animating : bool = false
var _animation_tween: Tween
var _show_update_indicator: bool = false
var _update_indicator_color: Color = Color.GREEN
var _forward_flow_indicators: Array[Dictionary] = []

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

	play_draw_animation()


static func newone(new_from_node: Control, new_to_node: Control, new_line_width: float = 2.0, new_line_color: Color = Color.BLACK, new_text: String = "", new_font: Font = ThemeDB.fallback_font, new_font_size: int = 16, new_font_color: Color = Color.WHITE, new_text_margin: float = 10.0) -> Conection:
	var new_conection: Conection = preload(scene_uid).instantiate()
	new_conection.from_node = new_from_node
	new_conection.to_node = new_to_node
	new_conection.line_width = new_line_width
	new_conection.line_color = new_line_color
	new_conection.text = new_text
	new_conection.font = new_font
	new_conection.font_size = new_font_size
	new_conection.font_color = new_font_color
	new_conection.text_margin = new_text_margin
	return new_conection


func _process(delta: float) -> void:
	var has_forward_flow_updates: bool = _update_forward_flow_indicators(delta)

	if _animating:
		_update_from_progress()  # actualizar cada frame mientras crece
		return
	# Mantener la línea alineada con los nodos (sin animar)
	points = _calc_points(1.0)
	_update_label()
	if has_forward_flow_updates:
		queue_redraw()


func _draw() -> void:
	if _animating and _show_update_indicator and points.size() > 0:
		draw_circle(points[points.size() - 1], Constants.CONECTION_UPDATE_INDICATOR_RADIUS, _update_indicator_color, true)

	for indicator in _forward_flow_indicators:
		var indicator_position: Variant = _get_forward_flow_indicator_position(indicator)
		if indicator_position == null:
			continue

		var indicator_center: Vector2 = indicator_position
		var indicator_color: Color = indicator.get("color", Color.BLACK)
		var half_size: Vector2 = Vector2.ONE * Constants.CONECTION_UPDATE_INDICATOR_RADIUS
		draw_rect(Rect2(indicator_center - half_size, half_size * 2.0), indicator_color, true)


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
	queue_redraw()


func play_draw_animation(duration: float = 0.5) -> void:
	_anim_progress = 0.0
	if _label:
		_label.modulate.a = 0.0
	_play_progress_animation(1.0, 1.0, duration, Callable(self, "_on_draw_anim_finished"))


func destroy_animated(duration: float = 0.5) -> void:
	_play_progress_animation(0.0, 0.0, duration, Callable(self, "_on_destroy_anim_finished"))


func _play_progress_animation(target_progress: float, target_alpha: float, duration: float, finished_callback: Callable) -> void:
	if _animation_tween and _animation_tween.is_valid():
		_animation_tween.kill()

	_animating = true
	points = _calc_points(_anim_progress)

	_animation_tween = create_tween()
	_animation_tween.tween_property(self, "_anim_progress", target_progress, duration)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	_animation_tween.parallel().tween_property(_label, "modulate:a", target_alpha, duration)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	_animation_tween.tween_callback(Callable(self, "_update_from_progress"))
	_animation_tween.finished.connect(finished_callback)


func _on_draw_anim_finished() -> void:
	_animating = false
	_animation_tween = null
	_show_update_indicator = false
	points = _calc_points(1.0)
	_update_label()
	queue_redraw()


func _on_destroy_anim_finished() -> void:
	_animating = false
	_animation_tween = null
	_anim_progress = 0.0
	points = _calc_points(0.0)
	queue_redraw()
	queue_free()


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


func set_line_style(new_line_width: float, new_line_color: Color) -> void:
	line_width = new_line_width
	line_color = new_line_color
	width = new_line_width
	default_color = new_line_color


func show_update_indicator(is_positive_update: bool) -> void:
	_show_update_indicator = true
	_update_indicator_color = positive_update_indicator_color if is_positive_update else negative_update_indicator_color
	queue_redraw()


func show_update_indicator_for_value(value: float) -> void:
	_show_update_indicator = true
	_update_indicator_color = _get_indicator_color_for_value(value)
	queue_redraw()


func show_forward_flow_indicator(value: float, start_node: Control = null, end_node: Control = null, duration: float = 0.5) -> void:
	var flow_start_node: Control = start_node if start_node != null else to_node
	var flow_end_node: Control = end_node if end_node != null else from_node
	_forward_flow_indicators.append({
		"progress": 0.0,
		"duration": maxf(duration, 0.001),
		"color": _get_indicator_color_for_value(value),
		"start_node": flow_start_node,
		"end_node": flow_end_node,
	})
	queue_redraw()


func _update_forward_flow_indicators(delta: float) -> bool:
	if _forward_flow_indicators.is_empty():
		return false

	var indicator_idx: int = _forward_flow_indicators.size() - 1
	while indicator_idx >= 0:
		var indicator: Dictionary = _forward_flow_indicators[indicator_idx]
		var duration: float = float(indicator.get("duration", 0.5))
		var progress: float = float(indicator.get("progress", 0.0)) + delta / duration
		if progress >= 1.0:
			_forward_flow_indicators.remove_at(indicator_idx)
		else:
			indicator["progress"] = progress
			_forward_flow_indicators[indicator_idx] = indicator
		indicator_idx -= 1

	return true


func _get_forward_flow_indicator_position(indicator: Dictionary) -> Variant:
	var start_node_variant: Variant = indicator.get("start_node")
	var end_node_variant: Variant = indicator.get("end_node")
	if not (start_node_variant is Control) or not (end_node_variant is Control):
		return null
	if not is_instance_valid(start_node_variant) or not is_instance_valid(end_node_variant):
		return null

	var start_control: Control = start_node_variant
	var end_control: Control = end_node_variant
	var start_center: Vector2 = start_control.global_position + (start_control.size * start_control.scale * 0.5)
	var end_center: Vector2 = end_control.global_position + (end_control.size * end_control.scale * 0.5)
	return to_local(start_center).lerp(to_local(end_center), float(indicator.get("progress", 0.0)))


func _get_indicator_color_for_value(value: float) -> Color:
	if is_zero_approx(value):
		return neutral_update_indicator_color

	if value > 0.0:
		return positive_update_indicator_color

	return negative_update_indicator_color
