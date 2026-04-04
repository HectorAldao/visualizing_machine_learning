extends Node


# Signals

@warning_ignore_start("unused_signal")

signal dataset_selected(data:Array[Dictionary], attrs: Array[String])

signal start_evaluation(data:Array[Dictionary])

signal drop_data()

signal all_data_droped()


# scenes/interface/nn/create_nn_menu/create_nn_menu.gd
signal plus(which: String, layer: int)
signal minus(which: String, layer: int)
signal create_nn_menu_button(which: String)


# 
signal add_layer()
signal remove_layer()


# 
signal add_neuron(layer: int)
signal remove_neuron(layer: int)
signal change_layer(layer: int)
signal update_conections(layer: int, neuron: int)


@warning_ignore_restore("unused_signal")

# Variables
