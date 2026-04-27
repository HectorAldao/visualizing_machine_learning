extends Node


# Signals

@warning_ignore_start("unused_signal")



signal dataset_selected(data:Array[Dictionary], attrs: Array[String])
signal dataset_selected_nn(data:Array[Dictionary], attrs: Array[String], nn_restrictions: Dictionary[int, int])

signal start_evaluation(data:Array[Dictionary])

signal drop_data()

signal all_data_droped()


# scenes/interface/nn/create_nn_menu/create_nn_menu.gd
signal load_nn
signal reload_nn
signal train_nn
signal update_nn_layer(layer_id: int)
signal establish_nn_dset_restrictions(restrictions: Dictionary[int, int])

# nn
signal add_layer
signal remove_layer
signal nn_inform_size(nn_position: Vector2)

# layer
signal add_neuron(layer_id: int)
signal remove_neuron(layer_id: int)

# neuron
signal info_neuron(neuron_id: int, layer_id: int)
signal nn_neuron_text_changed(layer_id: int, neuron_id: int, new_text: String)

var nn_layer_neuron_texts: Dictionary[int, Array] = {}


func set_nn_layer_neuron_texts(layer_id: int, texts: Array[String]) -> void:
	var cached_texts: Array[String] = texts.duplicate()
	nn_layer_neuron_texts[layer_id] = cached_texts
	print("[LOG] SignalsObserver cached %d neuron texts for layer %d" % [cached_texts.size(), layer_id])

	for neuron_id in range(cached_texts.size()):
		nn_neuron_text_changed.emit(layer_id, neuron_id, cached_texts[neuron_id])


func has_nn_neuron_text(layer_id: int, neuron_id: int) -> bool:
	if not nn_layer_neuron_texts.has(layer_id):
		return false

	return neuron_id >= 0 and neuron_id < nn_layer_neuron_texts[layer_id].size()


func get_nn_neuron_text(layer_id: int, neuron_id: int) -> String:
	if not has_nn_neuron_text(layer_id, neuron_id):
		return ""

	return str(nn_layer_neuron_texts[layer_id][neuron_id])

# dense
signal update_conections(layer_id: int, num_of_neurons: int)
signal update_all_conections

# nn_view
signal nn_view_want_nn_size
signal nn_view_set_nn_position(new_position: Vector2)

# algorithm nn
signal forward_step_completed(layer_idx, neuron_idx, output_value)
signal backward_step_completed(layer_idx, neuron_idx, delta_value)
signal weight_updated(layer_idx, neuron_idx, weight_idx, new_value)

# panel algorithm nn
signal train_nn_next_neuron(neuron_id: int, layer_id: int)
signal train_nn_next_layer(layer_id: int)
signal train_nn_next_step
signal train_nn_complete
signal test_nn_start

# window_nn

# panel training nn
signal save_nn

# panel export format
signal export_onnx
signal export_nnef

@warning_ignore_restore("unused_signal")
