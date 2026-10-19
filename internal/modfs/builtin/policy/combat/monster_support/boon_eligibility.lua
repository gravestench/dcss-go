local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")

local eligibility = {}

-- Monster flags come from source catalog arrays, not keyed sets.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Both self and allied Haste beams use the same stationary and stasis guard.
function eligibility.haste(ctx, target)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    return not has_flag(definition, flags.STATIONARY) and
        not has_flag(definition, flags.STASIS)
end

-- Might cannot improve a stationary monster's melee action.
function eligibility.might(ctx, target)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    return not has_flag(definition, flags.STATIONARY)
end

return eligibility
