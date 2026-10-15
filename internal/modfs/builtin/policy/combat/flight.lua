local catalog = require("policy.catalog")
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")

local flight = {}

local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Flight is a projection of saved actor state, never a second position type.
-- The player can fly through a spell duration or a form; monsters may fly
-- innately according to the committed monster catalog.
function flight.active(ctx, actor)
    local wind = ctx:get(actor, component.ZAP_FLIGHT)

    if wind and wind.remaining_aut > 0 then
        return true
    end

    if ctx:has(actor, component.PLAYER) then
        return forms.modifiers(ctx, actor).flight == "enable"
    end

    local identity = ctx:get(actor, component.ACTOR)

    if not identity then
        return false
    end

    local definition = catalog.get("monsters", identity.kind_id)

    return definition ~= nil and has_flag(definition.flags, "M_FLIES")
end

return flight
