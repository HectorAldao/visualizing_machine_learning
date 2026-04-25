extends PanelContainer

var _current_layer_cursor: int = 0
var _current_neuron_cursor: int = 0
var _sorted_layer_indices: Array[int] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalsObserver.train_nn.connect(_reset_training_cursor)
	$VBoxContainer/NextNeuronButton.pressed.connect(_on_next_neuron_pressed)
	$VBoxContainer/NextLayerButton.pressed.connect(_on_next_layer_pressed)
	$VBoxContainer/NextStepButton.pressed.connect(func(): SignalsObserver.train_nn_next_step.emit())
	$VBoxContainer/CompleteTrainButton.pressed.connect(func(): SignalsObserver.train_nn_complete.emit())
	$VBoxContainer/TestButton.pressed.connect(func(): SignalsObserver.test_nn_start.emit())


func _on_next_neuron_pressed() -> void:
	_ensure_training_cursor()
	var layer_id: int = _get_current_layer_id()
	if layer_id == -9999:
		return

	SignalsObserver.train_nn_next_neuron.emit(_current_neuron_cursor, layer_id)
	_advance_one_neuron_cursor()


func _on_next_layer_pressed() -> void:
	_ensure_training_cursor()
	if _sorted_layer_indices.is_empty():
		return

	_advance_one_layer_cursor()
	SignalsObserver.train_nn_next_layer.emit(_get_current_layer_id())


func _reset_training_cursor() -> void:
	_current_layer_cursor = 0
	_current_neuron_cursor = 0
	_sorted_layer_indices = _get_sorted_layer_indices(Variables.nn.nn_tmp_dict.keys())


func _ensure_training_cursor() -> void:
	if _sorted_layer_indices.is_empty():
		_reset_training_cursor()


func _advance_one_neuron_cursor() -> void:
	var layer_id: int = _get_current_layer_id()
	if layer_id == -9999:
		return

	_current_neuron_cursor += 1
	if _current_neuron_cursor >= _get_layer_neuron_count(layer_id):
		_advance_one_layer_cursor()


func _advance_one_layer_cursor() -> void:
	if _sorted_layer_indices.is_empty():
		return

	_current_layer_cursor += 1
	_current_neuron_cursor = 0
	if _current_layer_cursor >= _sorted_layer_indices.size():
		_current_layer_cursor = 0


func _get_current_layer_id() -> int:
	if _current_layer_cursor < 0 or _current_layer_cursor >= _sorted_layer_indices.size():
		return -9999
	return _sorted_layer_indices[_current_layer_cursor]


func _get_layer_neuron_count(layer_id: int) -> int:
	if not Variables.nn.nn_tmp_dict.has(layer_id):
		return 0
	return Variables.nn.nn_tmp_dict[layer_id].size()


func _get_sorted_layer_indices(keys: Array[int]) -> Array[int]:
	var hidden_layers: Array[int] = []
	for key in keys:
		if key > 0:
			hidden_layers.append(key)

	hidden_layers.sort()
	if -1 in keys:
		hidden_layers.append(-1)

	return hidden_layers
