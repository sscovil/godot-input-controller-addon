@icon("res://addons/input_controller/icon.svg")
class_name InputController
extends Node

signal input_detected(event: InputEvent, action: String, input_type: InputType)

enum InputType {
	ACTIVE,
	TAP,
	DOUBLE_TAP,
	PRESS,
	LONG_PRESS,
	HOLD,
	CANCEL,
}

const ActionHandlerMap = preload("res://addons/input_controller/action_handler_map.gd")
const ActionState = preload("res://addons/input_controller/action_state.gd")

## These values are used to determine the InputType of an InputEvent; all values are in seconds.
@export_group("Input Timing")

@export var max_button_tap: float = 0.2  # Max time for InputType.TAP.
@export var max_double_tap_delay: float = 0.1  # Max time between taps for InputType.DOUBLE_TAP.
@export var max_button_press: float = 0.5  # Max time for InputType.PRESS.
@export var max_long_press: float = 1.0  # Max time for InputType.LONG_PRESS.

## These values are used to identify which actions will be handled by which InputController
## methods, based on the input event propagation lifecycle explained here:
## https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html#how-does-it-work
##  
## By default, all actions that start with "ui_" will be handled by InputController._input(), and
## all other actions will be handled by InputController._unhandled_input(). This can be customized
## by changine these settings.
## 
## The "*" value is used as a wildcard, so "ui_*" means any action that starts with "ui_"; "*_move"
## means any action that ends with "_move"; "player_*_attack" means any action that starts with
## "player_" and ends with "_attack"; and "*" means all remaining unhandled actions.
## 
## More information about when to use each of the input event handler methods can be found here:
## 
## https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-input
## https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-shortcut-input
## https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-key-input
## https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-input
@export_group("Input Handlers")

@export var ui_inputs: Array[String] = ["ui_*"]
@export var shortcut_inputs: Array[String] = []
@export var unhandled_key_inputs: Array[String] = []
@export var unhandled_inputs: Array[String] = ["*"]

## If set to true (default), the InputController will consume InputEvents and stop them from
## propagating to other nodes by calling get_viewport().set_input_as_handled(). To allow the event
## to propagate after handling it, set this value to false. You might want to do this if you are only
## using the InputController for logging, analytics, or some other observational behavior.
## 
## NOTE: The InputController will only receive the input event if it has not already been handled by
## a child node, or a sibling node that appears below it in the scene tree.
@export_group("Event Propagation")

@export var set_input_as_handled: bool = true

## Map of input handler method names to their respective settings (defined above).
var settings: Dictionary = {
	"_input": &"ui_inputs",
	"_unhandled_shortcuts": &"shortcut_inputs",
	"_unhandled_key_input": &"unhandled_key_inputs",
	"_unhandled_input": &"unhandled_inputs",
}

## RegEx pattern to find a "*" character in a string and, if present, capture the text around it.
var wildcard: RegEx = RegEx.create_from_string("(.+)?\\*(.+)?")

## Collection of ActionState objects keyed by action name, used to track its current state.
var _actions: Dictionary = {}

## Object that contains lists of actions that should be handled by each input handler method.
var _handlers: ActionHandlerMap = ActionHandlerMap.new()


func _ready() -> void:
	map_actions_to_handlers()


func _input(event: InputEvent) -> void:
	if _handlers.has_actions("_input"):
		process_input(event, find_actions(event, _handlers.get_actions("_input")))


func _unhandled_input(event: InputEvent) -> void:
	if _handlers.has_actions("_unhandled_input"):
		process_input(event, find_actions(event, _handlers.get_actions("_unhandled_input")))


func _unhandled_key_input(event: InputEvent) -> void:
	if _handlers.has_actions("_unhandled_key_input"):
		process_input(event, find_actions(event, _handlers.get_actions("_unhandled_key_input")))


func _unhandled_shortcuts(event: InputEvent) -> void:
	if _handlers.has_actions("_unhandled_shortcuts"):
		process_input(event, find_actions(event, _handlers.get_actions("_unhandled_shortcuts")))


## Wrapper function for Time.get_ticks_msec() that returns the value in seconds, as a float.
func get_ticks() -> float:
	return float(Time.get_ticks_msec()) / 1000


## Search a given list of actions and return an array of actions that match a given event. An
## InputEvent can match more than one action, because multiple actions can have the same keys,
## joypad buttons, joystick inputs, etc. mapped to them.
## 
## @param event InputEvent: The event to check each action against.
## @param actions Array[StringName]: A list of actions to check.
## @return InputControllerAction: The first action that matches the event, or "" if no match found.
func find_actions(event: InputEvent, actions: Array[StringName]) -> Array[StringName]:
	return actions.filter(func (a): return event.is_action(a))


## Add each input action in a given list (or all actions from InputMap by default) to one of the
## input handler methods (_input, _unhandled_shortcuts, _unhandled_key_input, and _unhandled_input)
## based on InputController settings.
## 
## @param available_actions Array[StringName]: Defaults to the value of InputMap.get_actions().
func map_actions_to_handlers(available_actions: Array[StringName] = InputMap.get_actions()) -> void:
	# Initialize the action arrays in _handlers.
	_handlers.clear()
	 
	# Loop through each of the input handler methods in settings.
	for method in settings.keys():
		# End the loop early if no actions are available.
		if !available_actions:
				break
		
		# Loop through each of the settings for the current method.
		for setting in get(settings[method]):
			# End the loop early if no actions are available.
			if !available_actions:
				break
			
			# If the current setting contains only the wildcard character,
			if "*" == setting:
				# ...loop through a copy of available_actions, so we can modify the original.
				for action in available_actions.duplicate():
					# ...then add each action as a key to the _actions dictionary,
					_actions[action] = ActionState.new()
					# ...assign it to the _handlers dictionary under the current method,
					_handlers.add_action(method, action)
					# ...and remove it from the list of available actions.
					available_actions.pop_at(available_actions.find(action))
				
				# End the loop early, since there are no more actions available.
				break
			
			# Check if the current setting contains a "*" wildcard character.
			var matches: RegExMatch = wildcard.search(setting)
			
			# If the current setting contains a wildcard,
			if matches:
				# ...grab the strings to the left and right of the wildcard,
				var prefix: String = matches.strings[1]  # Can be an empty string.
				var suffix: String = matches.strings[2]  # Can be an empty string.
				
				# ...then loop through a copy of available_actions, so we can modify the original.
				for action in available_actions.duplicate():
					var has_prefix: bool = action.trim_prefix(prefix) != action
					var has_suffix: bool = action.trim_suffix(suffix) != action
					
					# If the action starts with prefix and ends with suffix,
					if (!prefix or has_prefix) and (!suffix or has_suffix):
						# ...add it as a key to the _actions dictionary,
						_actions[action] = ActionState.new()
						# ...assign it to the _handlers dictionary under the current method,
						_handlers.add_action(method, action)
						# ...and remove it from the list of available actions.
						available_actions.pop_at(available_actions.find(action))
			
			# If the current setting does not contain a wildcard and matches an available action,
			elif setting in available_actions:
				# ...add it as a key to the _actions dictionary,
				_actions[setting] = ActionState.new()
				# ...assign it to the _handlers dictionary under the current method,
				_handlers.add_action(method, setting)
				# ...and remove it from the list of available actions.
				available_actions.pop_at(available_actions.find(setting))


## Process InputEvent actions and, if InputController.set_input_as_handled is true, call
## get_viewport().set_input_as_handled() to prevent the InputEvent from propagating.
## 
## @param event InputEvent: The event that triggered the action.
## @param actions Array[StringName]: The actions to process.
## @return bool: True if the event was processed; otherwise, false.
func process_input(event: InputEvent, actions: Array[StringName]) -> bool:
	if !actions:
		return false  # No action to process.
	
	for action: StringName in actions:
		_process_action(event, action)
	
	# If configured to do so, prevent the InputEvent from propagating to other nodes.
	if set_input_as_handled:
		get_viewport().set_input_as_handled()
	
	return true  # Action was processed.


## Determine the InputType of a given InputEvent. This method is private because it updates the
## internal state of the InputController. It should only be called when certain conditions are met.
## 
## This method is a coroutine and, as such, must be called using the `await` keyword. See also:
## https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#awaiting-for-signals-or-coroutines
## 
## @param action ActionState: Current state of the action that triggered the InputEvent.
## @param delta float: Duration (in seconds) of the action input hold before it was released.
## @return InputType: The type of input, based on the duration of the action being held.
func _determine_input_type(action_state: ActionState, delta: float) -> InputType:
	# If a previous input for the same action occurred within the max_double_tap_delay limit,
	# then the two inputs combined are treated as an InputType.DOUBLE_TAP. We need to reset
	# prev_activated_at, so the previous call will see that and return InputType.CANCEL instead of
	# erroneously reporting an additional InputType.TAP after it's timeout is finished.
	if action_state.is_possible_double_tap and delta <= max_double_tap_delay:
		action_state.prev_activated_at = 0
		return InputType.DOUBLE_TAP
	
	# If the duration of the input is within the max_button_tap limit, it could be the first of two
	# subsequent taps that are intended to be an InputType.DOUBLE_TAP. To determine that, we need to
	# cache the current time (using get_ticks() for millisecond precision) and then set a timeout,
	# to allow a subsequent tap to occur. If it does so within the max_double_tap_delay limit, the
	# subsequent call will have already reset our cached time and returned InputType.DOUBLE_TAP, so
	# we should return InputType.CANCEL. If not, we should return InputType.TAP.
	if delta <= max_button_tap:
		action_state.prev_activated_at = get_ticks()
		await get_tree().create_timer(max_button_tap + max_double_tap_delay).timeout
		
		if action_state.prev_activated_at: 
			action_state.prev_activated_at = 0
			return InputType.TAP
		else:
			return InputType.CANCEL
	
	# If we rule out InputType.TAP and InputType.DOUBLE_TAP, the rest is pretty straightforward.
	if delta <= max_button_press:
		return InputType.PRESS
	
	if delta <= max_long_press:
		return InputType.LONG_PRESS
	
	return InputType.HOLD


## Process an event if it matches a given action. If the action is just pressed and it is not
## already active, emit the `input_detected` signal with `InputType.ACTIVE`, which indicates that
## the type of action has not yet been determined. If the action is just released and was active,
## mark it as inactive and emit the `input_detected` signal with the determined input type.
## 
## @param event InputEvent: The event that triggered the action.
## @param action StringName: The actions to process.
func _process_action(event: InputEvent, action: StringName) -> void:
	if !event.is_action(action):
		return
	
	var action_state: ActionState = _actions[action]
	
	# If the action just started, set last_activated_at and notify event listeners.
	if Input.is_action_just_pressed(action) and !action_state.is_active:
		action_state.last_activated_at = get_ticks()
		input_detected.emit(event, action, InputType.ACTIVE)
	
	# If the action just ended, determine the InputType and notify event listeners.
	elif Input.is_action_just_released(action) and action_state.is_active:
		var delta: float = get_ticks() - action_state.last_activated_at
		var input_type: InputType
		action_state.last_activated_at = 0  # Reset this before calling _determine_input_type().
		input_type = await _determine_input_type(action_state, delta)
		input_detected.emit(event, action, input_type)
