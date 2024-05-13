@icon("res://addons/input_controller/icon.svg")
class_name InputController
extends Node

enum InputType {
	ACTIVE,
	TAP,
	DOUBLE_TAP,
	PRESS,
	LONG_PRESS,
	HOLD,
	CANCEL,
}

signal input_detected(event: InputEvent, action: String, input_type: InputType)

# These values are used to determine the InputType of an InputEvent; all values are in seconds.
@export_group("Input Timing")

@export var max_button_tap: float = 0.2  # Max time for InputType.TAP.
@export var max_double_tap_delay: float = 0.1  # Max time between taps for InputType.DOUBLE_TAP.
@export var max_button_press: float = 0.5  # Max time for InputType.PRESS.
@export var max_long_press: float = 1.0  # Max time for InputType.LONG_PRESS.

# The following are used to identify which actions will be handled by which InputController methods,
# based on the input event propagation lifecycle explained here:
# 
# https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html#how-does-it-work
@export_group("Input Handlers")

# By default, all actions that start with "ui_" will be handled by InputController._input(), and
# all other actions will be handled by InputController._unhandled_input().
# 
# The "*" value is used as a wildcard that tells the method to consider any unhandled actions. This
# can be changed to a list of exact action names (e.g. "ui_left", "ui_right") and/or prefixes (e.g.
# "ui_*", "player_*").
# 
# More information about when to use each of the input event handler methods can be found here:
# 
# https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-input
# https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-key-input
# https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-shortcut-input
# https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-input
@export var ui_inputs: Array[String] = ["ui_*"]
@export var shortcut_inputs: Array[String] = []
@export var unhandled_key_inputs: Array[String] = []
@export var unhandled_inputs: Array[String] = ["*"]

@export_group("Event Propagation")

# If set to true (default value), the InputController will consume InputEvents and stop them from
# propagating to other nodes by calling get_viewport().set_input_as_handled(). To allow the event
# to propagate after handling it, set this value to false. You might want to do this if you are only
# using the InputController for logging, analytics, or some other observational behavior.
# 
# NOTE: The InputController will only receive the input event if it has not already been handled by
# a child node, or a sibling node that appears below it in the scene tree.
@export var set_input_as_handled: bool = true

# Used to determine the InputType of an action.
var action_timer: Dictionary = {}
var action_history: Dictionary = {}

# Used to loop through each configuration and cache its list of actions.
var ui_input_actions: Array[StringName] = []
var shortcut_input_actions: Array[StringName] = []
var unhandled_key_input_actions: Array[StringName] = []
var unhandled_input_actions: Array[StringName] = []


# Determine if any action in a given list matches a given event.
# 
# @param event InputEvent: The event to check each action against.
# @param actions Array[StringName]: A list of actions to check.
# @return InputControllerAction: The first action that matches the event, or "" if no match found.
func find_action(event: InputEvent, actions: Array[StringName]) -> String:
	for action in actions:
		if event.is_action(action):
			return action
	
	return ""  # No match found.


# Parse an InputEvent handler configuration array and return a list of input actions that match. If
# config array contains a "*" wildcard, this method will return the value of InputMap.get_actions().
# If config is an empty array, this method will return an empty array. If config contains any values
# that end in "*" (e.g. "ui_*", "player_*"), this method will include all actions that start with
# that prefix. All other config values will be treated as an exact match, so if the action exists,
# it will be included in the results. 
# 
# @param config Array[String]: A list of input action names, prefixes, or the "*" wildcard.
# @param actions: Array[StringName] A list of available actions, to avoid duplication.
# @return Array[String]: A list of input actions, based on the given config array. 
func get_actions_for_input_handler(
		config: Array[String],
		actions: Array[StringName]
	) -> Array[StringName]:
	if !config:
		return []

	var results: Array[StringName]
	
	if "*" in config:
		# Config contains a wildcard, so include all actions in results and clear the actions array.
		results = actions.duplicate()
		actions = []
		return results
	
	for action in config:
		if "*" == action.right(1):
			# Config ends with a wildcard, so include any actions that start with this prefix.
			var prefix: String = action.trim_suffix("*")
			var prefixed_actions: Array[StringName] = actions.filter(
				func(a): return a.trim_prefix(prefix) != a)
			
			for prefixed_action in prefixed_actions:
				if !results.has(prefixed_action):
					# Push prefixed action to results and remove it from actions.
					results.push_back(actions.pop_at(actions.find(prefixed_action)))
		else:
			# Config is a specific action name, so include it if valid and not already in results. 
			if actions.has(action) and !results.has(action):
				# Push action to results and remove it from actions.
				results.push_back(actions.pop_at(actions.find(action)))
	
	return results


# Determine the InputType of a given InputEvent. This method is private because it updates the
# internal state of the InputController, and should only be called when certain conditions are met.
# 
# This method is a coroutine and, as such, must be called using the `await` keyword. See also:
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#awaiting-for-signals-or-coroutines
# 
# @param action String: Action that triggered the InputEvent in question.
# @param delta float: Time (in seconds) between the action being pressed and released.
# @return InputType: The type of input, based on the duration of it being pressed.
func _determine_input_type(action: String, delta: float) -> InputType:
	if delta <= max_button_tap and action_history.has(action):
		action_history.erase(action)
		return InputType.DOUBLE_TAP
	
	if delta <= max_button_tap:
		# Cache the current tap in action_history and allow time for a subsequent tap.
		action_history[action] = Time.get_ticks_msec()
		await get_tree().create_timer(max_button_tap + max_double_tap_delay).timeout
		
		# If action_history hasn't been cleared yet, it was a single tap.
		if action_history.has(action): 
			action_history.erase(action)
			return InputType.TAP

		# Otherwise, it was a double tap and has already been resolved by the second InputEvent.
		return InputType.CANCEL
	
	if delta <= max_button_press:
		return InputType.PRESS
	
	if delta <= max_long_press:
		return InputType.LONG_PRESS
	
	return InputType.HOLD


# Wrapper function for Time.get_ticks_msec(); returns the value as a float instead of an integer.
func get_ticks() -> float:
	return float(Time.get_ticks_msec()) / 1000


# Track when an action was pressed. This enables _handle_action_released() to determine the input
# duration when the action is released. This method is private because it updates the internal
# state of the InputController, and should only be called when certain conditions are met.
# 
# @param event InputEvent: The event that triggered the action.
# @param action String: The action to handle.
func _handle_action_pressed(event: InputEvent, action: String) -> void:
	if action_timer.has(action):
		return  # This action is already being processed.
	
	action_timer[action] = get_ticks()
	input_detected.emit(event, action, InputType.ACTIVE)


# Determine the type of InputEvent action, then emit an "input_detected" signal with the result.
# This method is private because it updates the internal state of the InputController, and should
# only be called when certain conditions are met.
# 
# @param event InputEvent: The event that triggered the action.
# @param action String: The action to handle.
func _handle_action_released(event: InputEvent, action: String) -> void:
	if !action_timer.has(action):
		return  # This action was not handled by _handle_action_pressed().
	
	var previous: float = action_timer[action]
	action_timer.erase(action)  # This must happen before calling _get_input_type().
	
	var delta: float = get_ticks() - previous
	var input_type: InputType = await _determine_input_type(action, delta)
	input_detected.emit(event, action, input_type)


# Called when there is an input event. The input event propagates up through the node tree until a
# node consumes it.
# 
# It is only called if input processing is enabled, which is done automatically if this method is
# overridden, and can be toggled with set_process_input(). To consume the input event and stop it
# propagating further to other nodes, get_viewport().set_input_as_handled() can be called.
# 
# For gameplay input, _unhandled_input() and _unhandled_key_input() are usually a better fit as they
# allow the GUI to intercept the events first.
# 
# NOTE: This method is only called if the node is present in the scene tree (i.e. not an orphan).
func _input(event: InputEvent) -> void:
	if ui_input_actions:
		_process_input(event, find_action(event, ui_input_actions))


# Process a given InputEvent action and, if self.set_input_as_handled property is true, call
# get_viewport().set_input_as_handled() to prevent the InputEvent from propagating.
# 
# @param event InputEvent: The event that triggered the action.
# @param action String: The action to process.
# @return bool: True if the event was processed; otherwise, false.
func _process_input(event: InputEvent, action: String) -> bool:
	if !action:
		return false  # No action to process.
	
	if Input.is_action_just_pressed(action):
		_handle_action_pressed(event, action)
	elif Input.is_action_just_released(action):
		_handle_action_released(event, action)
	
	if set_input_as_handled:
		get_viewport().set_input_as_handled()
	
	return true


func _ready() -> void:
	var actions: Array[StringName] = InputMap.get_actions()
	
	ui_input_actions = get_actions_for_input_handler(ui_inputs, actions)
	shortcut_input_actions = get_actions_for_input_handler(shortcut_inputs, actions)
	unhandled_key_input_actions = get_actions_for_input_handler(unhandled_key_inputs, actions)
	unhandled_input_actions = get_actions_for_input_handler(unhandled_inputs, actions)


# Called when an InputEvent hasn't been consumed by _input() or any GUI Control item. It is
# called after _shortcut_input() and after _unhandled_key_input(). The input event propagates up
# through the node tree until a node consumes it.
# 
# It is only called if input processing is enabled, which is done automatically if this method is
# overridden, and can be toggled with set_process_input(). To consume the input event and stop it
# propagating further to other nodes, get_viewport().set_input_as_handled() can be called.
# 
# For gameplay input, this method is usually a better fit than _input(), as GUI events need a higher
# priority. For keyboard shortcuts, consider using _shortcut_input() instead, as it is called before
# this method. Finally, to handle keyboard events, consider using _unhandled_key_input() for
# performance reasons.
# 
# NOTE: This method is only called if the node is present in the scene tree (i.e. not an orphan).
func _unhandled_input(event: InputEvent) -> void:
	if unhandled_input_actions:
		_process_input(event, find_action(event, unhandled_input_actions))


# Called when an InputEventKey hasn't been consumed by _input() or any GUI Control item. It is
# called after _shortcut_input() but before _unhandled_input(). The input event propagates up
# through the node tree until a node consumes it.
# 
# It is only called if input processing is enabled, which is done automatically if this method is
# overridden, and can be toggled with set_process_input(). To consume the input event and stop it
# propagating further to other nodes, get_viewport().set_input_as_handled() can be called.
# 
# This method can be used to handle Unicode character input with Alt, Alt + Ctrl, and Alt + Shift
# modifiers, after shortcuts were handled. For gameplay input, this and _unhandled_input() are
# usually a better fit than _input(), as GUI events should be handled first. This method also
# performs better than _unhandled_input(), since unrelated events such as InputEventMouseMotion are
# automatically filtered. For shortcuts, consider using _shortcut_input() instead.
# 
# NOTE: This method is only called if the node is present in the scene tree (i.e. not an orphan).
func _unhandled_key_input(event: InputEvent) -> void:
	if unhandled_key_input_actions:
		_process_input(event, find_action(event, unhandled_key_input_actions))


# Called when an InputEventKey or InputEventShortcut hasn't been consumed by _input() or any GUI
# Control item. It is called before _unhandled_key_input() and _unhandled_input().
# 
# It is only called if input processing is enabled, which is done automatically if this method is
# overridden, and can be toggled with set_process_input(). To consume the input event and stop it
# propagating further to other nodes, get_viewport().set_input_as_handled() can be called.
# 
# This method can be used to handle shortcuts. For generic GUI events, use _input() instead.
# Gameplay events should usually be handled with _unhandled_input() or _unhandled_key_input().
# 
# NOTE: This method is only called if the node is present in the scene tree (i.e. not orphan).
func _unhandled_shortcuts(event: InputEvent) -> void:
	if shortcut_input_actions:
		_process_input(event, find_action(event, shortcut_input_actions))
