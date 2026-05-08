class_name NnEvalData extends Label


# Attribute name used as the key when AlgorithmNn emits sample dictionaries.
var atr_name: String
# Input neuron this value is visually attached to.
var target_neuron: Control

# Stable position beside the input neuron. Animations move away from and back to
# this point, instead of accumulating offsets over repeated samples.
var _home_position: Vector2 = Vector2.ZERO
var _tween: Tween

## Subscribes the label to training-value signals. Each label filters shared
## dictionaries by atr_name, so all input values can travel through one signal.
func _ready() -> void:
	SignalsObserver.add_change_eval_data.connect(_on_change_nn_eval_data)
	SignalsObserver.nn_eval_data_enter_network.connect(_on_enter_network)
	SignalsObserver.clear_nn_eval_data.connect(clear_value)
	modulate.a = 0.0

## Creates a value label already bound to the attribute it will display.
static func newone(new_atr_name: String) -> NnEvalData:
	var evaldata: NnEvalData = preload(Constants.SCENES.nn_eval_data).instantiate()
	evaldata.atr_name = new_atr_name
	return evaldata


## Stores the input neuron that should visually receive this value.
## NnEvalDataContainer uses this reference when recalculating layout.
func assign_neuron(neuron: Control) -> void:
	target_neuron = neuron


## Updates the resting position assigned by the container.
## The label is also snapped there so future animations start from a known state.
func set_home_position(new_home_position: Vector2) -> void:
	_home_position = new_home_position
	position = _home_position


## Reacts to the shared sample-value signal and ignores dictionaries that do not
## contain this label's attribute.
func _on_change_nn_eval_data(dict_of_values: Dictionary, animate_appear: bool) -> void:
	if not dict_of_values.has(atr_name):
		clear_value()
		return

	set_value(str(dict_of_values[atr_name]), animate_appear)


## Shows a new value. When animate_appear is true, the value enters from the
## left; otherwise it is placed beside the neuron immediately.
func set_value(new_value: String, animate_appear: bool = false) -> void:
	_kill_tween()
	text = new_value
	visible = true

	if animate_appear:
		position = _home_position + Vector2(-32.0, 0.0)
		modulate.a = 0.0
		_tween = create_tween()
		_tween.set_parallel(true)
		_tween.tween_property(self, "position", _home_position, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	else:
		position = _home_position
		modulate.a = 1.0


## Hides the value while keeping its attribute/neuron binding intact.
func clear_value() -> void:
	_kill_tween()
	text = ""
	modulate.a = 0.0
	position = _home_position


## Plays the "value enters the network" animation when AlgorithmNn starts the
## forward pass for the current sample.
func _on_enter_network() -> void:
	if text.is_empty() or modulate.a <= 0.0:
		return

	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", _home_position + Vector2(42.0, 0.0), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.35)


## Stops any previous animation before a new sample value or movement starts.
func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
