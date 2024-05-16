public class ActionState
{
    public ulong LastActivatedAt { get; set; } = 0;
    public ulong PrevActivatedAt { get; set; } = 0;

    public bool IsActive => LastActivatedAt > 0;

    public bool IsPossibleDoubleTap => PrevActivatedAt > 0;
}
