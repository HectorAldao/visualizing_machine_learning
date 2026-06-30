extends PanelContainer


@onready var onnx_button: Button = $VBoxContainer/ONNXButton
@onready var nnef_button: Button = $VBoxContainer/NNEFButton
@onready var cross_button: Button = %PanelExportFormatCrossButton

func _ready() -> void:
	onnx_button.pressed.connect(_on_onnx_pressed)
	nnef_button.pressed.connect(_on_nnef_pressed)
	cross_button.pressed.connect(func(): visible = not visible)


func _on_onnx_pressed() -> void:
	_request_export_path("onnx")


func _on_nnef_pressed() -> void:
	_request_export_path("nnef")


func _request_export_path(format: String) -> void:
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var temp_path := "user://network.%s" % format
		if _export_network(temp_path, format):
			_download_file_from_browser(temp_path, "network.%s" % format)
			visible = false
		return

	var file_dialog := FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.filters = PackedStringArray(["*.%s ; %s Files" % [format, format.to_upper()]])
	file_dialog.current_file = "network.%s" % format

	if "use_native_dialog" in file_dialog:
		file_dialog.use_native_dialog = true

	file_dialog.file_selected.connect(func(file_path: String):
		var normalized_path := _ensure_extension(file_path, format)
		if _export_network(normalized_path, format):
			visible = false
		file_dialog.queue_free()
	)

	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)

	add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.4)


func _export_network(file_path: String, format: String) -> bool:
	if Variables.nn.nn_dict.is_empty():
		push_error("No hay red neuronal para exportar.")
		return false

	match format:
		"onnx":
			ONNXExporter.new().export_network(Variables.nn.nn_dict, Variables.nn.nn_bias_dict, Variables.nn.nn_func_dict, file_path)
			SignalsObserver.export_onnx.emit()
		"nnef":
			NNEFExporter.new().export_to_nnef(file_path, Variables.nn.nn_dict, Variables.nn.nn_bias_dict, Variables.nn.nn_func_dict)
			SignalsObserver.export_nnef.emit()
		_:
			return false

	return FileAccess.file_exists(file_path)


func _download_file_from_browser(file_path: String, download_name: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("No se pudo preparar la descarga del archivo exportado.")
		return

	var content_base64 := Marshalls.raw_to_base64(file.get_buffer(file.get_length()))
	file.close()

	var js_bridge = Engine.get_singleton("JavaScriptBridge")
	js_bridge.get_interface("window").godotNnExportContentBase64 = content_base64
	js_bridge.get_interface("window").godotNnExportFileName = download_name
	js_bridge.eval(
		"""
		(function () {
			const contentBase64 = window.godotNnExportContentBase64 || "";
			const fileName = window.godotNnExportFileName || "network";
			const binary = atob(contentBase64);
			const bytes = new Uint8Array(binary.length);
			for (let i = 0; i < binary.length; i += 1) {
				bytes[i] = binary.charCodeAt(i);
			}
			const blob = new Blob([bytes], { type: "application/octet-stream" });
			const url = URL.createObjectURL(blob);
			const link = document.createElement("a");
			link.href = url;
			link.download = fileName;
			document.body.appendChild(link);
			link.click();
			link.remove();
			URL.revokeObjectURL(url);
		})();
		""",
		true
	)


func _ensure_extension(file_path: String, extension: String) -> String:
	if file_path.get_extension().to_lower() == extension:
		return file_path

	return "%s.%s" % [file_path, extension]
