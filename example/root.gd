extends Node2D

const InputType = InputController.InputType

@onready var input_controller = $InputController
@onready var joy_pad: Sprite2D = $JoyPad


func _ready():
	input_controller.connect("input_detected", _on_input_detected)


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


func _get_device_name(event: InputEvent) -> String:
	return "keyboard" if is_instance_of(event, InputEventKey) else "device %d" % event.device


func _on_input_detected(event: InputEvent, action: String, input_type: InputType):
	if action in joy_pad.action_map.keys():
		match input_type:
			InputType.ACTIVE: joy_pad.call("activate", action)
			InputType.CANCEL: joy_pad.call("deactivate", action)
	
	var input_text: String = get_input_type_label(input_type)
	
	if input_text:
		prints(action, input_text, "on", _get_device_name(event))
