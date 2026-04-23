extends PanelContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/NextNeuronButton.pressed.connect(func(): SignalsObserver.train_nn_next_neuron.emit())
	$VBoxContainer/NextLayerButton.pressed.connect(func(): SignalsObserver.train_nn_next_layer.emit())
	$VBoxContainer/NextStepButton.pressed.connect(func(): SignalsObserver.train_nn_next_step.emit())
	$VBoxContainer/CompleteTrainButton.pressed.connect(func(): SignalsObserver.train_nn_complete.emit())
	$VBoxContainer/TestButton.pressed.connect(func(): SignalsObserver.test_nn_start.emit())
