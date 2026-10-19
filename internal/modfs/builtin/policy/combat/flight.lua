local catalog = require("policy.catalog")
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")

local flight = {}

-- Form restrictions override innate and jewelry flight when deciding permanence.
function flight.permanent(ctx, player)
    return forms.modifiers(ctx, player).flight ~= "forbid" and
        (effects.sum(ctx, player, capabilities.PERMANENT_FLIGHT) > 0 or
            jewellery_effects.has(ctx, player,
                jewellery_capabilities.PERMANENT_FLIGHT))
end

-- Monster flight may come from catalog flags instead of a player status component.
local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Example: flight.active(ctx, actor) with active flight form -> true while its duration lasts
-- Flight is a projection of saved actor state, never a second position type.
-- The player can fly through a spell duration or a form; monsters may fly
-- innately according to the committed monster catalog.
function flight.active(ctx, actor)
    local is_player = ctx:has(actor, component.PLAYER)

    if is_player then
        local form = forms.modifiers(ctx, actor).flight

        if form == "forbid" then
            return false
        end

        if form == "enable" then
            return true
        end

        if flight.permanent(ctx, actor) then
            return true
        end
    end

    local wind = ctx:get(actor, component.ZAP_FLIGHT)

    if wind and wind.remaining_aut > 0 then
        return true
    end

    if is_player then
        return false
    end

    local identity = ctx:get(actor, component.ACTOR)

    if not identity then
        return false
    end

    local definition = catalog.get("monsters", identity.kind_id)

    return definition ~= nil and has_flag(definition.flags, "M_FLIES")
end

-- Tengu's flight perk only applies while flight is active, regardless of its source.
function flight.tengu_perk(ctx, player)
    return flight.active(ctx, player) and
        effects.sum(ctx, player, capabilities.TENGU_FLIGHT_PERK) > 0
end

return flight
