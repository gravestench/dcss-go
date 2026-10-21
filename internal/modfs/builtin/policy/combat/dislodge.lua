-- Physical displacement shares the defender's actual body size and the
-- Mountain Boots exception. Wind and trample must make the same decision
-- before either changes an actor's saved position.
local artefacts = require("ids.artefacts")
local catalog = require("policy.catalog")
local component = require("constants.component")
local equipment = require("policy.combat.equipment")
local forms = require("policy.magic.effects.forms.player")
local size = require("constants.size")

local dislodge = {}

-- A worn, usable pair of Mountain Boots is the player's source exception
-- to knockback. Melded boots are excluded by the equipment owner.
function dislodge.resists(ctx, entity)
    if not ctx:has(entity, component.PLAYER) then
        return false
    end

    local boots = equipment.worn(ctx, entity, {
        boots = true,
    }).boots
    local artefact = boots and
        ctx:get(boots.entity, component.ITEM_ARTEFACT)

    return artefact and
        artefact.unique_id == artefacts.UNRAND_MOUNTAIN_BOOTS or false
end

-- Use a player's current form size or a monster's catalog body size. This
-- rank is shared by wind distance and the trample size contest.
function dislodge.body_rank(ctx, entity)
    if ctx:has(entity, component.PLAYER) then
        local identity = ctx:get(entity, component.PLAYER)
        local species = catalog.get("species", identity.species_id)
        local form = forms.modifiers(ctx, entity)

        return size.rank[form.size or species.size] or
            size.rank[size.MEDIUM]
    end

    local actor = ctx:get(entity, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return size.rank[definition.size_id] or size.rank[size.MEDIUM]
end

return dislodge
