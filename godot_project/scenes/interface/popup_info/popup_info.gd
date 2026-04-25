class_name PopupInfo extends Control

@onready var popup: PopupPanel = $CanvasLayer/PopupPanel



static func newone() -> PopupInfo:
	var new_popupinfo: PopupInfo = preload(Constants.SCENES.popupinfo).instantiate()
	return new_popupinfo


func show_popup() -> void:
	popup.show()


func hide_popup() -> void:
	popup.hide()
