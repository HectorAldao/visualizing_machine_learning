extends Node

var nn: NeuralNetworkLogial = NeuralNetworkLogial.newone()

var queue_nn_train: Array[int] = []

var nn_output_class_decoder: Dictionary = {}

var nn_layer_neuron_texts: Dictionary[int, Array] = {}

var nn_clicked_neuron_id: int = -1
var nn_clicked_neuron_layer_id: int = -9999
var nn_clicked_neuron_window_snapshot: Dictionary = {}

var dtree_clicked_node_id: int = -1
var dtree_clicked_node_window_snapshot: Dictionary = {}


func _ready() -> void:
	SignalsObserver.return_to_main_menu.connect(_reset_nn_variables)


func _reset_nn_variables() -> void:
	nn = NeuralNetworkLogial.newone()
	queue_nn_train.clear()
	nn_output_class_decoder.clear()
	nn_layer_neuron_texts.clear()
	nn_clicked_neuron_id = -1
	nn_clicked_neuron_layer_id = -9999
	nn_clicked_neuron_window_snapshot.clear()
	dtree_clicked_node_id = -1
	dtree_clicked_node_window_snapshot.clear()
