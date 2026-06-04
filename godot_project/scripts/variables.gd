extends Node

var nn: NeuralNetworkLogial = NeuralNetworkLogial.newone()

var queue_nn_train: Array[int] = []

var nn_output_class_decoder: Dictionary = {}

var nn_layer_neuron_texts: Dictionary[int, Array] = {}

var nn_clicked_neuron_id: int = -1
var nn_clicked_neuron_layer_id: int = -9999
var nn_clicked_neuron_window_snapshot: Dictionary = {}
