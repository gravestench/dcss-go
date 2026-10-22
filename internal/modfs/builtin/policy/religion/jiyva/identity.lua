-- The source uses monster genus, not glyph or item appetite, to decide
-- which actors belong to Jiyva's slime family. Worship state is one saved
-- player component shared by conversion, feeding, and periodic effects.
local component = require("constants.component")
local gods = require("constants.gods")
local monsters = require("ids.monsters")

local identity = {}

local slime_genera = {
    [monsters.MONS_JELLY] = true,
    [monsters.MONS_FLOATING_EYE] = true,
    [monsters.MONS_GLOWING_ORANGE_BRAIN] = true,
}

-- A modded subtype can inherit the source genus and receive the same
-- passive without registering another special case in this policy.
function identity.slime(definition)
    return slime_genera[definition.genus_id] or false
end

-- Penance suspends passive effects while retaining the worship record;
-- conversion has its own attempt semantics and can request raw worship.
function identity.worship(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if state and state.god_id == gods.JIYVA then
        return state
    end

    return nil
end

-- Zero-rank slime passives apply only while Jiyva is in good standing.
function identity.passive(ctx, player)
    local state = identity.worship(ctx, player)

    return state and (state.penance[gods.JIYVA] or 0) == 0
end

return identity
