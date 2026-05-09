extends Node

var nn: NeuralNetworkLogial = NeuralNetworkLogial.newone()

var queue_nn_train: Array[int] = []

var nn_output_class_decoder: Dictionary = {}

var nn_layer_neuron_texts: Dictionary[int, Array] = {}
