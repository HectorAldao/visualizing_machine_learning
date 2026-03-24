extends Node


# Signals

@warning_ignore_start("unused_signal")

signal dataset_selected(data:Array[Dictionary], attrs: Array[String])

signal start_evaluation(data:Array[Dictionary])

signal drop_data()

signal all_data_droped()


@warning_ignore_restore("unused_signal")


# Variables
