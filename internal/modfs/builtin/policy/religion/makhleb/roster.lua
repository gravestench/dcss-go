-- Makhleb's servant abilities and wrath choose from the same two source
-- demon tiers. Keep these IDs together so future catalog changes cannot
-- leave summon selection and saved-source validation disagreeing.
local monsters = require("ids.monsters")

local roster = {}

roster.lesser = {
    monsters.MONS_HELLWING,
    monsters.MONS_NEQOXEC,
    monsters.MONS_ORANGE_DEMON,
    monsters.MONS_SMOKE_DEMON,
    monsters.MONS_YNOXINUL,
}

roster.greater = {
    monsters.MONS_EXECUTIONER,
    monsters.MONS_GREEN_DEATH,
    monsters.MONS_BLIZZARD_DEMON,
    monsters.MONS_BALRUG,
    monsters.MONS_CACODEMON,
}

-- Restore checks a tier, not just the union: a lower-rank invocation
-- cannot claim to have produced a greater demon from this patron.
function roster.contains(kind_id, tier)
    local choices = roster[tier]

    if not choices then
        return false
    end

    for _, candidate in ipairs(choices) do
        if candidate == kind_id then
            return true
        end
    end

    return false
end

return roster
