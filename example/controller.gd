extends Sprite2D

const ACTIVE: Color = Color(100, 100, 100, 255)
const INACTIVE: Color = Color(1, 1, 1, 255)

@onready var Up: Sprite2D = $Up
@onready var Down: Sprite2D = $Down
@onready var Left: Sprite2D = $Left
@onready var Right: Sprite2D = $Right
@onready var LeftStick: Sprite2D = $LeftStick
@onready var RightStick: Sprite2D = $RightStick
@onready var GreenButton: Sprite2D = $GreenButton
@onready var RedButton: Sprite2D = $RedButton
@onready var BlueButton: Sprite2D = $BlueButton
@onready var YellowButton: Sprite2D = $YellowButton
@onready var LeftBumper: Sprite2D = $LeftBumper
#@onready var LeftTrigger: Sprite2D = $LeftTrigger
@onready var RightBumper: Sprite2D = $RightBumper
#@onready var RightTrigger: Sprite2D = $RightTrigger
@onready var StartButton: Sprite2D = $StartButton
@onready var SelectButton: Sprite2D = $SelectButton
@onready var PowerButton: Sprite2D = $PowerButton
@onready var TouchPad: Sprite2D = $TouchPad

@onready var action_map: Dictionary = {
	"dpad_up": Up,
	"dpad_down": Down,
	"dpad_left": Left,
	"dpad_right": Right,
	"left_stick_up": LeftStick,
	"left_stick_down": LeftStick,
	"left_stick_left": LeftStick,
	"left_stick_right": LeftStick,
	"left_stick_button": LeftStick,
	"right_stick_up": RightStick,
	"right_stick_down": RightStick,
	"right_stick_left": RightStick,
	"right_stick_right": RightStick,
	"right_stick_button": RightStick,
	"green_button": GreenButton,
	"red_button": RedButton,
	"blue_button": BlueButton,
	"yellow_button": YellowButton,
	"left_bumper": LeftBumper,
	#"left_trigger": LeftTrigger,
	"right_bumper": RightBumper,
	#"right_trigger": RightTrigger,
	"start": StartButton,
	"select": SelectButton,
	"power_button": PowerButton,
	"touchpad": TouchPad,
}

var activator: Callable = func(action): action_map[action].set_modulate(ACTIVE)
var deactivator: Callable = func(action): action_map[action].set_modulate(INACTIVE)

func activate(action: String) -> void:
	if !action_map.has(action):
		return  # Nothing to activate.
	
	activator.call_deferred(action)


func deactivate(action: String) -> void:
	if !action_map.has(action):
		return  # Nothing to deactivate.
	
	deactivator.call_deferred(action)
