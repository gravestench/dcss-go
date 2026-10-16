-- Mirrors game.CommandKind. Keep command names in Lua at policy call sites.
local command_kind = {
    MOVE = 1,
    UPSTAIRS = 2,
    DOWNSTAIRS = 3,
    PICKUP = 4,
    WAIT = 5,
    INSPECT = 6,
    QUAFF = 7,
    DROP = 8,
    WIELD = 9,
    OPEN_DOOR = 10,
    CLOSE_DOOR = 11,
    WEAR = 12,
    TAKE_OFF = 13,
    CONTINUE_EQUIPMENT = 14,
    CANCEL_EQUIPMENT = 15,
    FIRE = 16,
    THROW = 17,
    MEMORISE = 18,
    CANCEL_MEMORISE = 19,
    CAST = 20,
    FORCE_CAST = 21,
    ABILITY = 22,
    EVOKE_WAND = 23,
    READ = 24,
}

return command_kind
