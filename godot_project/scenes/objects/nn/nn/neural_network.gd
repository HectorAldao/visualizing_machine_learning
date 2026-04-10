class_name NeuralNetwork extends MarginContainer


@onready var layers: HBoxContainer = $Layers

var nn_dict: Dictionary[int, int]


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


func _on_add_layer() -> void:
	# Get the index for the new layer
	var n_layers: int =  layers.get_child_count() - 1  # The index starts at 0 with the input layer
	# Create it
	var new_layer: Layer = Layer.newone(n_layers)
	# And add it as a child
	layers.add_child(new_layer)
	layers.move_child(new_layer, -2)


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
