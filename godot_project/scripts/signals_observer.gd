extends Node


# Signals

@warning_ignore_start("unused_signal")

signal dataset_selected(data:Array[Dictionary], attrs: Array[String])

signal start_evaluation(data:Array[Dictionary])

signal drop_data()

signal all_data_droped()


# res://scenes/interface/nn/create_nn_menu/create_nn_menu.gd
signal plus(which: String)
signal minus(which: String)
signal create_nn_menu_button(which: String)



@warning_ignore_restore("unused_signal")

# Variables
