-- Dowan and Duvessa are a linked pair even after one has been polymorphed.
-- The first saved original class, not its current appearance, identifies
-- which twin another source action must affect.
local component = require("constants.component")
local monsters = require("ids.monsters")

local twins = {}

-- Read the original class when polymorph replaced the visible body.
local function class(ctx, entity)
    local form = ctx:get(entity, component.MONSTER_POLYMORPH)

    if form and form.original_kind_id ~= "" then
        return form.original_kind_id
    end

    local actor = ctx:get(entity, component.ACTOR)

    return actor and actor.kind_id or nil
end

-- Search all generated floors. The source unique pair can be separated
-- by a stair or banishment, but a dead twin is no longer a partner.
function twins.other(ctx, entity)
    local own = class(ctx, entity)
    local wanted

    if own == monsters.MONS_DUVESSA then
        wanted = monsters.MONS_DOWAN
    elseif own == monsters.MONS_DOWAN then
        wanted = monsters.MONS_DUVESSA
    else
        return nil
    end

    for _, candidate in ipairs(ctx:query({
        component.ACTOR,
        component.HEALTH,
    })) do
        local health = ctx:get(candidate, component.HEALTH)

        if candidate ~= entity and health.current > 0 and
            class(ctx, candidate) == wanted then
            return candidate
        end
    end

    return nil
end

return twins
