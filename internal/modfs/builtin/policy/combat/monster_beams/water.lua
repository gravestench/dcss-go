local catalog = require("policy.catalog")
local component = require("constants.component")
local form_ids = require("constants.form_ids")
local habitats = require("constants.monster_habitats")
local holiness = require("constants.monster_holiness")
local undead_states = require("constants.undead_states")
local water = require("policy.character.water")

local drowning = {}

local unbreathing = {
    [holiness.UNDEAD] = true,
    [holiness.NONLIVING] = true,
    [holiness.PLANT] = true,
}

-- fight.cc:get_resistible_fraction leaves 60% impact damage even when
-- the defender cannot drown in the magical water.
function drowning.immune(ctx, target)
    if ctx:has(target, component.PLAYER) then
        local player = ctx:get(target, component.PLAYER)
        local species = catalog.get("species", player.species_id)
        local form = ctx:get(target, component.PLAYER_FORM)

        return species.undead_type == undead_states.UNDEAD or
            water.can_swim(ctx, target) or
            form and (form.form_id == form_ids.TREE or
                form.form_id == form_ids.ICE_BEAST)
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if definition.habitat_id == habitats.WATER or
        definition.habitat_id == habitats.AMPHIBIOUS then
        return true
    end

    for _, kind in ipairs(definition.holiness or {}) do
        if unbreathing[kind] then
            return true
        end
    end

    return false
end

function drowning.damage(ctx, target, raw)
    if drowning.immune(ctx, target) then
        return raw - math.floor(raw * 40 / 100)
    end

    return raw
end

return drowning
