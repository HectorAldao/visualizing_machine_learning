class_name Neuron extends Button

var _id: int = -2
var _layer_id: int = -2


var _normal_theme: Theme
var _resalted_theme: Theme = preload(Constants.THEMES.resalted_neuron)
var _clicked_theme: Theme = preload(Constants.THEMES.clicked_neuron)


func _ready() -> void:
	_normal_theme = theme
	pressed.connect(_on_pressed)
	SignalsObserver.forward_step_completed.connect(_on_training_step_completed)
	SignalsObserver.backward_step_completed.connect(_on_training_step_completed)
	SignalsObserver.nn_layer_resalted.connect(_on_layer_resalted)
	SignalsObserver.train_nn.connect(_reset_evaluated_theme)
	SignalsObserver.train_nn_next_step.connect(_reset_evaluated_theme)
	SignalsObserver.train_nn_complete.connect(_reset_evaluated_theme)
	SignalsObserver.nn_neuron_text_changed.connect(_on_neuron_text_changed)
	_apply_cached_text()


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


func _on_layer_resalted(layer_id: int) -> void:
	_set_evaluated(layer_id == _layer_id)


func _on_neuron_text_changed(layer_id: int, neuron_id: int, new_text: String) -> void:
	if layer_id != _layer_id or neuron_id != _id:
		return

	text = new_text
	print("[LOG] Neuron %d on layer %d changed text to '%s'" % [_id, _layer_id, new_text])


func _apply_cached_text() -> void:
	if has_nn_neuron_text(_layer_id, _id):
		_on_neuron_text_changed(_layer_id, _id, get_nn_neuron_text(_layer_id, _id))


func _set_evaluated(is_evaluated: bool) -> void:
	var target_theme: Theme = _resalted_theme if is_evaluated else _normal_theme
	if theme != target_theme:
		theme = target_theme


func _reset_evaluated_theme() -> void:
	_set_evaluated(false)


func has_nn_neuron_text(layer_id: int, neuron_id: int) -> bool:
	if not Variables.nn_layer_neuron_texts.has(layer_id):
		return false

	return neuron_id >= 0 and neuron_id < Variables.nn_layer_neuron_texts[layer_id].size()


func get_nn_neuron_text(layer_id: int, neuron_id: int) -> String:
	if not has_nn_neuron_text(layer_id, neuron_id):
		return ""

	return str(Variables.nn_layer_neuron_texts[layer_id][neuron_id])
