-- monster.cc:monster::cloud_immune gives the Cloud Mage immunity to every
-- cloud, independent of elemental resistance and cloud-specific effects.
local component = require("constants.component")
local monsters = require("ids.monsters")
local artefacts = require("ids.artefacts")
local equipment = require("policy.combat.equipment")

local immunity = {}

-- Cloud Mage and the Robe of Clouds bypass every cloud kind before per-element resistance.
-- Example: Cloud Mage and a player wearing the Robe of Clouds bypass every cloud kind.
function immunity.all(ctx, actor)
    local state = ctx:get(actor, component.ACTOR)

    if state then
        return state.kind_id == monsters.MONS_CLOUD_MAGE
    end

    if actor ~= ctx:player() then
        return false
    end

    local body = equipment.worn(ctx, actor, {
        body = true,
    }).body

    if not body then
        return false
    end

    local artefact = ctx:get(body.entity, component.ITEM_ARTEFACT)

    return artefact and artefact.unique_id ==
        artefacts.UNRAND_RCLOUDS or false
end

return immunity
