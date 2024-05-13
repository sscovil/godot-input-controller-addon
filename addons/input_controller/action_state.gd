class_name ActionState
extends Node
## This class is used in the InputController._actions dictionary to hold the state of each action.

var last_activated_at: float = 0
var prev_activated_at: float = 0

var is_active: bool:
	get: return last_activated_at > 0

var is_possible_double_tap: bool:
	get: return prev_activated_at > 0
