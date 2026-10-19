local component = require("constants.component")

local stats = {}

-- Example: with base_hd = 5, one drain degree, and no Wretched state,
-- stats.hit_dice(ctx, monster, definition, base_hd) -> 4 hit dice
-- Source: mon-act.cc:monster::get_hit_dice. Draining reduces HD before
-- wretchedness applies its temporary quarter reduction.
function stats.hit_dice(ctx, monster, definition, base_hd)
    local drained = ctx:get(monster, component.MONSTER_DRAINED)
    local degree = drained and drained.remaining_aut > 0 and
        drained.degree or 0
    local hd = math.max(1, (base_hd or definition.hd) - degree)
    local wretched = ctx:get(monster, component.WRETCHED)

    if wretched and wretched.remaining_aut > 0 then
        hd = math.max(1, math.floor(hd * 3 / 4))
    end

    return hd
end

-- Aura of Brilliance empowers spells by five HD without changing melee,
-- natural regeneration, or source monster durability.
function stats.spell_hit_dice(ctx, monster, definition, base_hd)
    local hd = stats.hit_dice(ctx, monster, definition, base_hd)
    local state = ctx:get(monster, component.MONSTER_EMPOWERED_SPELLS)

    if state and state.remaining_aut > 0 then
        return hd + 5
    end

    return hd
end

return stats
