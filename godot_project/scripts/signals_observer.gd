extends Node


# Signals

@warning_ignore_start("unused_signal")



signal dataset_selected(data:Array[Dictionary], attrs: Array[String])

signal start_evaluation(data:Array[Dictionary])

signal drop_data()

signal all_data_droped()


# scenes/interface/nn/create_nn_menu/create_nn_menu.gd
signal load_nn
signal reload_nn
signal train_nn
signal update_nn_layer(layer_id: int)

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



@warning_ignore_restore("unused_signal")
