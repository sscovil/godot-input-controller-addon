using System.Collections.Generic;
using Godot;

public class ActionHandlerMap
{
    public HashSet<StringName> Input { get; set; } = [];
    public HashSet<StringName> ShortcutInput { get; set; } = [];
    public HashSet<StringName> UnhandledKeyInputs { get; set; } = [];
    public HashSet<StringName> UnhandledInputs { get; set; } = [];

    public void AddAction(string method, StringName action) => _ = GetActions(method).Add(action);
    public void Removection(string method, StringName action) => _ = GetActions(method).Remove(action);

    public void Clear(string method = "")
    {
        switch (method)
        {
            case "":
                Input.Clear();
                ShortcutInput.Clear();
                UnhandledKeyInputs.Clear();
                UnhandledInputs.Clear();
                break;
            default:
                GetActions(method).Clear();
                break;
        }
    }

    public bool HasActions(string method) => GetActions(method).Count > 0;

    public HashSet<StringName> GetActions(string method)
    {
        return method switch
        {
            "Input" => Input,
            "ShortcutInput" => ShortcutInput,
            "UnhandledKeyInputs" => UnhandledKeyInputs,
            "UnhandledInputs" => UnhandledInputs,
            _ => [],
        };
    }
}