class_name Neuron extends Button

var _id: int = -2
var _layer_id: int = -2


var _normal_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_normal_scale = scale
	pivot_offset = size / 2.0
	pressed.connect(_on_pressed)
	SignalsObserver.forward_step_completed.connect(_on_training_step_completed)
	SignalsObserver.backward_step_completed.connect(_on_training_step_completed)
	SignalsObserver.train_nn.connect(_reset_evaluated_scale)
	SignalsObserver.train_nn_next_step.connect(_reset_evaluated_scale)
	SignalsObserver.train_nn_complete.connect(_reset_evaluated_scale)


static func newone(new_id: int, new_layer_id) -> Neuron:
	var new_neuron: Neuron = preload(Constants.SCENES.neuron).instantiate()
	new_neuron._id = new_id
	new_neuron._layer_id = new_layer_id
	return new_neuron


func _on_pressed() -> void:
	SignalsObserver.info_neuron.emit(_id, _layer_id)
	pass


func _on_training_step_completed(layer_id: int, neuron_id: int, _value: float) -> void:
	_set_evaluated(neuron_id == _id and layer_id == _layer_id)


func _set_evaluated(is_evaluated: bool) -> void:
	var target_scale: Vector2 = Constants.NEURON_EVALUATED_SCALE if is_evaluated else _normal_scale
	if scale != target_scale:
		scale = target_scale


func _reset_evaluated_scale() -> void:
	_set_evaluated(false)
