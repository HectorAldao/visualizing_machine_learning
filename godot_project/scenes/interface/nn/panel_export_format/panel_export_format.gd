extends PanelContainer


@onready var onnx_button: Button = $VBoxContainer/ONNXButton
@onready var nnef_button: Button = $VBoxContainer/NNEFButton

func _ready() -> void:
	onnx_button.pressed.connect(_on_onnx_pressed)
	nnef_button.pressed.connect(_on_nnef_pressed)


func _on_onnx_pressed() -> void:
	SignalsObserver.export_onnx.emit()
	visible = false


func _on_nnef_pressed() -> void:
	SignalsObserver.export_nnef.emit()
	visible = false
