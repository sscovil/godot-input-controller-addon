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
@onready var RightBumper: Sprite2D = $RightBumper
@onready var StartButton: Sprite2D = $StartButton
@onready var SelectButton: Sprite2D = $SelectButton
@onready var PowerButton: Sprite2D = $PowerButton
@onready var TouchPad: Sprite2D = $TouchPad

@onready var action_map: Dictionary = {
	"joy_dpad_up": Up,
	"joy_dpad_down": Down,
	"joy_dpad_left": Left,
	"joy_dpad_right": Right,
	"joy_left_stick_up": LeftStick,
	"joy_left_stick_down": LeftStick,
	"joy_left_stick_left": LeftStick,
	"joy_left_stick_right": LeftStick,
	"joy_left_stick_button": LeftStick,
	"joy_right_stick_up": RightStick,
	"joy_right_stick_down": RightStick,
	"joy_right_stick_left": RightStick,
	"joy_right_stick_right": RightStick,
	"joy_right_stick_button": RightStick,
	"joy_green_button": GreenButton,
	"joy_red_button": RedButton,
	"joy_blue_button": BlueButton,
	"joy_yellow_button": YellowButton,
	"joy_left_bumper": LeftBumper,
	"joy_right_bumper": RightBumper,
	"joy_start": StartButton,
	"joy_select": SelectButton,
	"joy_power_button": PowerButton,
	"joy_touchpad": TouchPad,
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
