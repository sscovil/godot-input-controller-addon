using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Godot;

[Tool]
[Icon("res://addons/input_controller/icon.svg")]
public partial class InputController : Node
{
    [Signal]
    public delegate void input_detectedEventHandler(InputEvent inputEvent, string action, InputType inputType);

    private input_detectedEventHandler _inputDetected;
    public event input_detectedEventHandler InputDetected
    {
        add => _inputDetected += value;
        remove
        {
            if (_inputDetected != null && value != null)
            {
                _inputDetected -= value;
            }
        }
    }

    [ExportGroup("Input Timing")]
    // These values are used to determine the InputType of an InputEvent; all values are in seconds.
    [Export] public float MaxButtonTap { get; set; } = 0.2f;  // Max time for InputType.TAP.
    [Export] public float MaxDoubleTapDelay { get; set; } = 0.1f; // Max time between taps for InputType.DOUBLE_TAP.
    [Export] public float MaxButtonPress { get; set; } = 0.5f; // Max time for InputType.PRESS.
    [Export] public float MaxLongPress { get; set; } = 1.0f; // Max time for InputType.LONG_PRESS.

    [ExportGroup("Input Handlers")]
    // These values are used to identify which actions will be handled by which InputController
    // methods, based on the input event propagation lifecycle explained here:
    // https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html#how-does-it-work
    //  
    // By default, all actions that start with "ui_" will be handled by InputController._input(), and
    // all other actions will be handled by InputController._unhandled_input(). This can be customized
    // by changine these settings.
    // 
    // The "*" value is used as a wildcard, so "ui_*" means any action that starts with "ui_"; "*_move"
    // means any action that ends with "_move"; "player_*_attack" means any action that starts with
    // "player_" and ends with "_attack"; and "*" means all remaining unhandled actions.
    // 
    // More information about when to use each of the input event handler methods can be found here:
    // 
    // https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-input
    // https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-shortcut-input
    // https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-key-input
    // https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-input
    [Export] public string[] UiInputs { get; set; } = ["ui_*"];
    [Export] public string[] ShortcutInputs { get; set; } = [];
    [Export] public string[] UnhandledKeyInputs { get; set; } = [];
    [Export] public string[] UnhandledInputs { get; set; } = ["*"];

    [ExportGroup("Event Propagation")]

    /// <summary>
    /// If set to true (default), the InputController will consume InputEvents and stop them from
    /// propagating to other nodes by calling get_viewport().set_input_as_handled(). To allow the event
    /// to propagate after handling it, set this value to false. You might want to do this if you are only
    /// using the InputController for logging, analytics, or some other observational behavior.
    /// 
    /// NOTE: The InputController will only receive the input event if it has not already been handled by
    /// a child node, or a sibling node that appears below it in the scene tree.
    /// </summary>
    [Export] private bool SetInputAsHandled { get; set; } = true;

    /// <summary>
    /// Map of input handler method names to their respective settings (defined above).
    /// </summary>
    private Dictionary<string, string[]> _settings = [];

    /// <summary>
    /// RegEx pattern to find a "*" character in a string and, if present, capture the text around it.
    /// <summary>
    private readonly RegEx _wildcard = RegEx.CreateFromString("(.+)?\\*(.+)?");

    public Dictionary<StringName, ActionState> Actions { get; set; } = [];

    public ActionHandlerMap Handlers { get; set; } = new ActionHandlerMap();

    public override void _Ready()
    {
        _settings = new()
        {
            ["Input"] = UiInputs,
            ["ShortcutInput"] = ShortcutInputs,
            ["UnhandledKeyInput"] = UnhandledKeyInputs,
            ["UnhandledInput"] = UnhandledInputs,
        };
        MapActionsToHandlers();
    }

    public override void _Input(InputEvent @event)
    {
        if (Handlers.HasActions("Input"))
            _ = ProcessInput(@event, FindActions(@event, Handlers.GetActions("Input")));
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (Handlers.HasActions("UnhandledInput"))
            _ = ProcessInput(@event, FindActions(@event, Handlers.GetActions("UnhandledInput")));
    }

    public override void _UnhandledKeyInput(InputEvent @event)
    {
        if (Handlers.HasActions("UnhandledKeyInput"))
            _ = ProcessInput(@event, FindActions(@event, Handlers.GetActions("UnhandledKeyInput")));
    }

    public override void _ShortcutInput(InputEvent @event)
    {
        if (Handlers.HasActions("ShortcutInput"))
            _ = ProcessInput(@event, FindActions(@event, Handlers.GetActions("ShortcutInput")));
    }

    /// <summary>
    /// Search a given list of actions and return the first one that matches a given event.
    /// </summary>
    /// <param name="event">The event to check each action against.</param>
    /// <param name="actions">A list of actions to check.</param>
    /// <returns>The first action that matches the event, or "" if no match found.</returns>
    public HashSet<StringName> FindActions(InputEvent @event, HashSet<StringName> actions)
    {
        HashSet<StringName> result = [];

        foreach (var action in actions)
            if (@event.IsAction(action))
                _ = result.Add(action);

        return result;
    }

    /// <summary>
    /// Add each input action in a given list (or all actions from InputMap by default) to one of the
    /// input handler methods (_input, _ShortcutInput, _unhandled_key_input, and _unhandled_input)
    /// based on InputController settings.
    /// </summary>
    /// <param name="availableActions">Defaults to the value of InputMap.get_actions().</param>
    public void MapActionsToHandlers(StringName[] availableActions = null)
    {
        Handlers.Clear();

        availableActions ??= InputMap.GetActions().ToArray();

        if (availableActions == null)
            return;

        HashSet<StringName> actionSet = new(availableActions);

        foreach (var method in _settings.Keys)
        {
            if (!_settings.TryGetValue(method, out var settings))
                continue;

            foreach (var setting in settings)
            {
                if (setting.Equals("*"))
                    foreach (var action in actionSet.ToList())
                    {
                        if (action == null)
                            continue;

                        Actions[action] = new();
                        Handlers.AddAction(method, action);
                        _ = actionSet.Remove(action);
                    }
                else
                {
                    var matches = _wildcard.Search(setting);

                    if (matches != null && matches.Strings.Length > 0)
                    {
                        var prefix = matches.Strings[1];
                        var suffix = matches.Strings[2];

                        foreach (var action in actionSet.ToList())
                        {
                            if (action == null)
                                continue;

                            var hasPrefix = action.ToString().StartsWith(prefix);
                            var hasSuffix = action.ToString().EndsWith(suffix);

                            if ((string.IsNullOrEmpty(prefix) || hasPrefix) &&
                                (string.IsNullOrEmpty(suffix) || hasSuffix))
                            {
                                Actions[action] = new();
                                Handlers.AddAction(method, action);
                                _ = actionSet.Remove(action);
                            }
                        }
                    }
                    else if (actionSet.Contains(setting))
                    {
                        Actions[setting] = new();
                        Handlers.AddAction(method, setting);
                        _ = actionSet.Remove(setting);
                    }
                }
            }
        }
    }
    /// <summary>
    /// Process InputEvent actions and, if InputController.set_input_as_handled is true, call
    /// get_viewport().set_input_as_handled() to prevent the InputEvent from propagating.
    /// </summary>
    /// <param name="event">The event that triggered the action.</param>
    /// <param name="actions">The actions to process.</param>
    /// <returns>True if the event was processed; otherwise, false.</returns>
    private bool ProcessInput(InputEvent @event, HashSet<StringName> actions)
    {
        if (actions == null || actions.Count == 0)
            return false;  // No action to process.

        foreach (var action in actions)
            ProcessAction(@event, action);

        // If configured to do so, prevent the InputEvent from propagating to other nodes.
        if (SetInputAsHandled)
            GetViewport().SetInputAsHandled();

        return true;  // Action was processed.
    }

    /// <summary>
    /// Determine the InputType of a given InputEvent. This method is private because it updates the
    /// internal state of the InputController. It should only be called when certain conditions are met.
    /// 
    /// This method is a coroutine and, as such, must be called using the `await` keyword. See also:
    /// https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#awaiting-for-signals-or-coroutines
    /// </summary>
    /// <param name="actionState">Current state of the action that triggered the InputEvent.</param>
    /// <param name="delta">Duration (in seconds) of the action input hold before it was released.</param>
    /// <returns>The type of input, based on the duration of the action being held.</returns>
    private async Task<InputType> DetermineInputType(ActionState actionState, float delta)
    {
        // If a previous input for the same action occurred within the max_double_tap_delay limit,
        // then the two inputs combined are treated as an InputType.DOUBLE_TAP. We need to reset
        // prev_activated_at, so the previous call will see that and return InputType.CANCEL instead of
        // erroneously reporting an additional InputType.TAP after it's timeout is finished.
        lock (actionState)
            if (actionState.IsPossibleDoubleTap && delta <= MaxDoubleTapDelay)
            {
                actionState.PrevActivatedAt = 0;
                return InputType.DOUBLE_TAP;
            }

        // If the duration of the input is within the max_button_tap limit, it could be the first of two
        // subsequent taps that are intended to be an InputType.DOUBLE_TAP. To determine that, we need to
        // cache the current time (using get_ticks() for millisecond precision) and then set a timeout,
        // to allow a subsequent tap to occur. If it does so within the max_double_tap_delay limit, the
        // subsequent call will have already reset our cached time and returned InputType.DOUBLE_TAP, so
        // we should return InputType.CANCEL. If not, we should return InputType.TAP.
        if (delta <= MaxButtonTap)
        {
            actionState.PrevActivatedAt = Time.GetTicksMsec();

            _ = await ToSignal(GetTree().CreateTimer(MaxButtonTap + MaxDoubleTapDelay), SceneTreeTimer.SignalName.Timeout);

            if (actionState.IsPossibleDoubleTap)
            {
                actionState.PrevActivatedAt = 0;
                return InputType.TAP;
            }
            else
                return InputType.CANCEL;
        }

        // If we rule out InputType.TAP and InputType.DOUBLE_TAP, the rest is pretty straightforward.
        return delta <= MaxButtonPress ? InputType.PRESS :
            delta <= MaxLongPress ? InputType.LONG_PRESS :
            InputType.HOLD;
    }

    private async void ProcessAction(InputEvent @event, StringName action)
    {
        if (!Actions.TryGetValue(action, out var actionState))
            return;

        // If the action just started, set last_activated_at and notify event listeners.
        if (Input.IsActionJustPressed(action) && !actionState.IsActive)
        {
            actionState.LastActivatedAt = Time.GetTicksMsec();
            _inputDetected?.Invoke(@event, action, InputType.ACTIVE);
            _ = EmitSignal("input_detected", @event, action, InputType.ACTIVE.ToString());
        }
        // If the action just ended, determine the InputType and notify event listeners.
        else if (Input.IsActionJustReleased(action) && actionState.IsActive)
        {
            var delta = (Time.GetTicksMsec() - actionState.LastActivatedAt) / 1000;

            actionState.LastActivatedAt = 0;  // Reset this before calling _determine_input_type().
            var inputType = await DetermineInputType(actionState, delta);

            _inputDetected?.Invoke(@event, action, inputType);
            _ = EmitSignal("input_detected", @event, action, InputType.ACTIVE.ToString());
        }
    }
}
