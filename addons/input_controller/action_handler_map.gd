class_name ActionHandlerMap
extends Object
## This class is used to store a list of input actions for each InputController handler method.

var _input: Array[StringName] = []
var _unhandled_shortcuts: Array[StringName] = []
var _unhandled_key_input: Array[StringName] = []
var _unhandled_input: Array[StringName] = []


func add_action(method: String, action: StringName) -> void:
	self.get(method).push_back(action)


func clear(method: String = "") -> void:
	if method:
		self.get(method).clear()
	else:
		_input.clear()
		_unhandled_shortcuts.clear()
		_unhandled_key_input.clear()
		_unhandled_input.clear()


func has_actions(method: String) -> bool:
	return self.get(method).size() > 0


func get_actions(method: String) -> Array[StringName]:
	return self.get(method)


func remove_action(method: String, action: StringName) -> void:
	self.get(method).pop_at(self.get(method).find(action))
