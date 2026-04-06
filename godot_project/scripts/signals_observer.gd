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
signal update_nn_layer(layer_id)

# nn
signal add_layer
signal remove_layer

# layer
signal add_neuron(layer_id)
signal remove_neuron(layer_id)

# dense
signal update_conections(layer_id, num_of_neurons)
signal update_all_conections



@warning_ignore_restore("unused_signal")
