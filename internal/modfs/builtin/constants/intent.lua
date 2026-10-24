-- An intent is the action selected for this turn after interpreting a command or AI decision.

-- Mirrors the resolved ECS intent-kind contract in internal/ecs/components.go.
local intent = {
    MOVE = 1,
    MELEE = 2,
    PICKUP = 3,
    UPSTAIRS = 4,
    DOWNSTAIRS = 5,
    WAIT = 6,
    QUAFF = 7,
    OPEN_DOOR = 8,
    CLOSE_DOOR = 9,
    DROP = 10,
    WIELD = 11,
    SPELL = 12,
    ABILITY = 12,
    RANGED = 13,
    MEMORISE = 14,
    PLAYER_SPELL = 15,
    CAST = 15,
    CHANNEL_WAIT = 16,
    PLAYER_ABILITY = 17,
    EVOKE_WAND = 18,
    READ = 19,
    JEWELLERY_ON = 20,
    JEWELLERY_OFF = 21,
    PRAYER = 22,
    EVOKE_ITEM = 23,
    MONSTER_MOVE = 1,
    MONSTER_MELEE = 2,
    MONSTER_WAIT = 6,
    MONSTER_ABILITY = 12,
}

return intent
