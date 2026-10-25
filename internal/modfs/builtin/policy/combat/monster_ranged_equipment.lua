-- A monster's equipped launcher supplies the same live stats whether
-- its shot lands on the player or Ru sends it into another monster.
local artefact_properties = require(
    "policy.item_generation.artefacts.properties")
local artefact_ids = require("ids.artefact_properties")
local component = require("constants.component")

local ranged_equipment = {}

-- Copy catalog weapon properties before applying live artefact bonuses.
-- Neither a generated ego nor a modded item mutates shared definitions.
function ranged_equipment.launcher_profile(ctx, launcher)
    local source = launcher.definition.weapon
    local profile = {}

    for name, value in pairs(source) do
        profile[name] = value
    end

    profile.damage = profile.damage + artefact_properties.value(ctx,
        launcher.entity, artefact_ids.BASE_DAMAGE)
    profile.hit = profile.hit + artefact_properties.value(ctx,
        launcher.entity, artefact_ids.BASE_ACCURACY)
    profile.speed = profile.speed + artefact_properties.value(ctx,
        launcher.entity, artefact_ids.BASE_DELAY)

    return profile
end

-- Selecting an alternate launcher exchanges two saved equipment slots.
-- Both defenders observe the same weapon after the shot completes.
function ranged_equipment.swap_launcher(ctx, worn)
    local alternate = worn.alternate_weapon

    ctx:set(alternate.entity, component.EQUIPPED, {
        slot = "weapon",
    })

    if worn.weapon then
        ctx:set(worn.weapon.entity, component.EQUIPPED, {
            slot = "alternate_weapon",
        })
    end
end

return ranged_equipment
