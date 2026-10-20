local component = require("constants.component")

local stats = {}

-- A derived undead body keeps its source creature's HD on the entity. The
-- generic zombie and skeleton catalog entries deliberately have no fixed HD.
function stats.base_hit_dice(ctx, monster, definition)
    local authored = ctx:get(monster, component.VAULT_ACTOR_OVERRIDES)

    if authored and authored.hit_dice > 0 then
        return authored.hit_dice
    end

    local derived = ctx:get(monster, component.SUMMON_STATS)

    if derived then
        return derived.hd
    end

    if not definition.hd then
        error("monster has no fixed or derived hit dice " .. definition.id)
    end

    return definition.hd
end

-- Example: with base_hd = 5, one drain degree, and no Wretched state,
-- stats.hit_dice(ctx, monster, definition, base_hd) -> 4 hit dice
-- Source: mon-act.cc:monster::get_hit_dice. Draining reduces HD before
-- wretchedness applies its temporary quarter reduction.
function stats.hit_dice(ctx, monster, definition, base_hd)
    local drained = ctx:get(monster, component.MONSTER_DRAINED)
    local degree = drained and drained.remaining_aut > 0 and
        drained.degree or 0
    local hd = math.max(1, (base_hd or
        stats.base_hit_dice(ctx, monster, definition)) - degree)
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
