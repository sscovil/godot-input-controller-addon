# InputController add-on for Godot game engine

This add-on provides a helpful node that can detect different types of inputs, including taps,
double taps, standard button presses, and long button presses.

**NOTE:** This is a pre-release version that has only been manually tested with Godot v4.2.2.stable
so far. There are some known issues, and it is not yet suitable for use in a public release.

## Installation

1. Copy the `addons/input_controller` directory into the `addons/` directory of your Godot project,
creating that directory if it does not yet exist.

2. In Godot, go to `Project` > `Project Settings` > `Plugins` and find the InputController plugin,
then check the status box to enable it.

## Usage

1. Add an `InputController` node to your scene tree.
2. Connect an event handler function in your script to the `input_detected` signal from the
`InputController`.

```gdscript
const InputType = InputController.InputType

func _ready():
	InputController.connect("input_detected", _on_input_detected)

func _on_input_detected(event: InputEvent, action: String, input_type: InputType):
	match type:
		InputType.TAP:
			prints(action, "tapped")
		InputType.DOUBLE_TAP:
			prints(action, "double tapped")
		InputType.PRESS:
			prints(action, "pressed")
		InputType.LONG_PRESS:
			prints(action, "long pressed")
		InputType.HOLD:
			prints(action, "held")
```

## Configuration

The following exported values can be modified in the Godot Editor Inpsector, or programmatically
by directly accessing the properties of the node.

### Input Timing

Use these settings to fine tune the timing that is used to differentiate between a tap, double tap,
standard button press, and long button press. All values are in seconds.

| Setting Name         | Type    | Default |
|----------------------|---------|---------|
| Max Button Tap       | `float` | 0.2     |
| Max Double Tap Delay | `float` | 0.1     |
| Max Button Press     | `float` | 0.5     |
| Max Long Tap         | `float` | 1       |

Here is an example of how to adjust these values in a script:

```gdscript
func _ready():
	$InputController.max_button_tap = 0.18
	$InputController.max_double_tap_delay = 0.12
	$InputController.max_button_press = 0.45
	$InputController.max_long_press = 0.85
```

### Input Handlers

Use these settings to customize which event handlers are used to detect different types of actions,
or which actions to listen for. By default, an `InputController` will handle all actions that start
with the `ui_` prefix in the `InputController._input()` method; and all other actions in the
`InputController._unhandled_input()` method.

| Setting Name         | Type            | Default  |
|----------------------|-----------------|----------|
| UI Inputs            | `Array[String]` | ["ui_*"] |
| Shortcut Inputs      | `Array[String]` | []       |
| Unhandled Key Inputs | `Array[String]` | []       |
| Unhandled Inputs     | `Array[String]` | ["*"]    |

When determining which actions will be handled by which method, `InputController` will start with
`ui_inputs` and assign any actions that match the configuration settings to be handled by the
`_input()` method. If the wildcard `"*"` were used here, all actions would be assigned and no other
`InputController` methods would be used.

Each setting is evaluated in the order they appear above. Values like `"ui_*"` are treated as action
name prefixes; any that do not end with a `*` wildcard are treated as exact action names. This gives
you very granualar control over which actions are handled by each `InputController` instance.

More information about how input events are processed in Godot can be found
[here](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html#how-does-it-work).

More about which input event handler to use for which types of actions can be found here:

* https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-input
* https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-key-input
* https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-shortcut-input
* https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-input

### Event Propagation

If set to `true` (default value), the `InputController` will consume an `InputEvent` and stop it
from propagating to other nodes by calling `get_viewport().set_input_as_handled()`. To allow the
event to propagate after handling it, set this value to false. You might want to do this if you are
only using the `InputController` for logging, analytics, or some other observational behavior.
 
| Setting Name         | Type   | Default |
|----------------------|--------|---------|
| Set Input as Handled | `bool` | `true`  |

**NOTE:** The `InputController` will only receive the input event if it has not already been handled
by a child node, or a sibling node that appears below it in the scene tree.
