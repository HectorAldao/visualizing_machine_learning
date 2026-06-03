class_name NeuralNetwork extends MarginContainer


@onready var layers: HBoxContainer = $Layers

var nn_dict: Dictionary[int, int]
var nn_bias_dict: Dictionary[int, Array]
var _is_canvas_update_queued: bool = false


func _ready() -> void:

	for layer in layers.get_children():
		layers.remove_child(layer)
		layer.queue_free()

	layers.add_child(Layer.newone(0))
	layers.add_child(Layer.newone(-1))
	#var in_layer: Layer = layers.get_child(0)
	#in_layer._id = 0
	#var out_layer: Layer = layers.get_child(-1)
	#out_layer._id = -1

	SignalsObserver.add_layer.connect(_on_add_layer)
	SignalsObserver.remove_layer.connect(_on_remove_layer)

	SignalsObserver.nn_view_want_nn_size.connect(func(): SignalsObserver.nn_inform_size.emit(size))
	SignalsObserver.nn_view_set_nn_position.connect(func(new_position): position = new_position)

	SignalsObserver.update_all_conections.emit.call_deferred()
	resized.connect(_queue_canvas_update)
	_queue_canvas_update()


func _on_add_layer() -> void:
	# Get the index for the new layer
	var n_layers: int =  layers.get_child_count() - 1  # The index starts at 0 with the input layer
	# Create it
	var new_layer: Layer = Layer.newone(n_layers)
	# And add it as a child
	layers.add_child(new_layer)
	layers.move_child(new_layer, -2)
	_queue_canvas_update()


func _on_remove_layer() -> void:
	var n_layers: int =  layers.get_child_count()

	# If there only is one neuron left, its not possible to delete it
	if n_layers == 2:
		print("[LOG] NeuralNetwork cant remove more layers")
		return

	# Delete the last layer
	var last_layer: Layer = layers.get_child(-2)
	layers.remove_child(last_layer)
	last_layer.queue_free()
	_queue_canvas_update()


func request_canvas_update() -> void:
	_queue_canvas_update()


func _queue_canvas_update() -> void:
	if _is_canvas_update_queued or not is_inside_tree():
		return

	_is_canvas_update_queued = true
	_update_canvas_size.call_deferred()


func _update_canvas_size() -> void:
	_is_canvas_update_queued = false

	var core_bounds: Rect2 = _get_layers_content_global_bounds()
	if core_bounds.size == Vector2.ZERO:
		return

	var visual_bounds: Rect2 = _get_visual_global_bounds(core_bounds)
	var margin: float = Constants.NN_CANVAS_MARGIN
	var margin_left: float = max(margin, core_bounds.position.x - visual_bounds.position.x + margin)
	var margin_top: float = max(margin, core_bounds.position.y - visual_bounds.position.y + margin)
	var margin_right: float = max(margin, visual_bounds.end.x - core_bounds.end.x + margin)
	var margin_bottom: float = max(margin, visual_bounds.end.y - core_bounds.end.y + margin)

	_add_int_theme_constant_override("margin_left", int(ceil(margin_left)))
	_add_int_theme_constant_override("margin_top", int(ceil(margin_top)))
	_add_int_theme_constant_override("margin_right", int(ceil(margin_right)))
	_add_int_theme_constant_override("margin_bottom", int(ceil(margin_bottom)))

	var new_minimum_size: Vector2 = Vector2(
		ceil(core_bounds.size.x + margin_left + margin_right),
		ceil(core_bounds.size.y + margin_top + margin_bottom)
	)
	if custom_minimum_size != new_minimum_size:
		custom_minimum_size = new_minimum_size


func _add_int_theme_constant_override(constant_name: StringName, value: int) -> void:
	if get_theme_constant(constant_name) == value:
		return

	add_theme_constant_override(constant_name, value)


func _get_layers_content_global_bounds() -> Rect2:
	var bounds: Rect2 = Rect2()
	var has_bounds: bool = false

	for layer in layers.get_children():
		if not (layer is Control):
			continue

		var found_child_bounds: bool = false
		for neuron in layer.get_children():
			if not (neuron is Control) or not neuron.visible:
				continue

			var neuron_rect: Rect2 = neuron.get_global_rect()
			if neuron_rect.size == Vector2.ZERO:
				continue

			bounds = neuron_rect if not has_bounds else bounds.merge(neuron_rect)
			has_bounds = true
			found_child_bounds = true

		if not found_child_bounds:
			var layer_rect: Rect2 = (layer as Control).get_global_rect()
			if layer_rect.size != Vector2.ZERO:
				bounds = layer_rect if not has_bounds else bounds.merge(layer_rect)
				has_bounds = true

	return bounds


func _get_visual_global_bounds(base_bounds: Rect2) -> Rect2:
	var bounds: Rect2 = base_bounds
	for container_name in ["NnEvalDataContainer", "NnEvalDataContainerOut", "NnEvalDataContainerExpected"]:
		var container: Control = get_node_or_null(container_name)
		if container == null or not container.visible:
			continue

		for child in container.get_children():
			if not (child is Control) or not child.visible:
				continue

			var child_rect: Rect2 = (child as Control).get_global_rect()
			if child_rect.size == Vector2.ZERO:
				continue

			bounds = bounds.merge(child_rect)

	return bounds
