extends Node2D

const InputType = InputController.InputType


func get_input_type_label(type: InputType) -> String:
	match type:
		InputType.TAP:
			return "tapped"
		InputType.DOUBLE_TAP:
			return "double tapped"
		InputType.PRESS:
			return "pressed"
		InputType.LONG_PRESS:
			return "long pressed"
		InputType.HOLD:
			return "held"
	
	return ""


func _on_input_detected(_event: InputEvent, action: String, input_type: InputType):
	if input_type == InputType.ACTIVE:
		$Controller.call_thread_safe("activate", action)
	elif input_type != InputType.CANCEL:
		$Controller.call_thread_safe("deactivate", action)
	
	var input_text: String = get_input_type_label(input_type)

	if input_text:
		prints(action, input_text)


func _ready():
	$InputController.connect("input_detected", _on_input_detected)
