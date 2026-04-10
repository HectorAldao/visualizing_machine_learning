class_name Layer extends VBoxContainer

var _id: int = -2

func _ready() -> void:

	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	add_child(Neuron.newone(0, _id))

	alignment = BoxContainer.ALIGNMENT_CENTER
	SignalsObserver.add_neuron.connect(_on_add_neuron)
	SignalsObserver.remove_neuron.connect(_on_remove_neuron)


static func newone(new_id) -> Layer:
	var new_layer: Layer = preload(Constants.SCENES.layer).instantiate()
	new_layer._id = new_id
	return new_layer


func _on_add_neuron(layer_id: int) -> void:
	if layer_id == _id:

		# Create it
		var new_neuron: Neuron = Neuron.newone(get_child_count(), _id)
		# And add it as a child
		add_child(new_neuron)

		# Inform the controller
		SignalsObserver.update_conections.emit(_id, get_child_count())


func _on_remove_neuron(layer_id: int) -> void:
	if layer_id == _id:

		# If there only is one neuron left, its not possible to delete it
		if get_child_count() == 1:
			print("[LOG] Layer {0} cant remove its last neuron".format(_id))
			return

		# Delete the last neuron
		var last_neuron: Neuron = get_child(-1)
		remove_child(last_neuron)
		last_neuron.queue_free()

		# Inform the controller
		SignalsObserver.update_conections.emit(_id, get_child_count())
