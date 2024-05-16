#if TOOLS
using Godot;

[Tool]
public partial class InputControllerPlugin : EditorPlugin
{
    public override void _EnterTree()
    {
        var texture = GD.Load<Texture2D>("res://addons/InputController/icon.png");

        var script = GD.Load<Script>("res://addons/InputController/InputController.cs");
        AddCustomType("InputController", "Node", script, texture);
    }

    public override void _ExitTree() => RemoveCustomType("InputController");
}
#endif