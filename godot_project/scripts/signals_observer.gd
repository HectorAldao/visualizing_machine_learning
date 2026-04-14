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
signal train_nn_next_neuron
signal train_nn_next_layer
signal train_nn_next_step

@warning_ignore_restore("unused_signal")
