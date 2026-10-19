-- Example: A Wanderer with no weapon gift receives fallback gear in an open slot.
-- Source: ng-wanderer.cc; fill gaps left by randomized starting gear.
local gear = require("policy.character.starting_gear")
local items = require("ids.items")
local jobs = require("ids.jobs")

local rule = {}

-- Fill missing Wanderer weapon and armour slots after the randomized gifts occupy their slots.
function rule.extra(species, generated, occupied)
    local attributes = generated and generated.attributes or {}
    local strength = species.strength + (attributes.strength or 0)
    local intelligence = species.intelligence + (attributes.intelligence or 0)
    local dexterity = species.dexterity + (attributes.dexterity or 0)
    local grants = {}

    if not occupied.body then
        local armour = strength > intelligence and
            items.ARM_LEATHER_ARMOUR or items.ARM_ROBE

        grants[#grants + 1] = {
            kind_id = armour,
            quantity = 1,
        }
    end

    if not occupied.weapon then
        local weapon = dexterity > strength and
            items.WPN_DAGGER or items.WPN_CLUB

        grants[#grants + 1] = {
            kind_id = weapon,
            quantity = 1,
        }
    end

    return grants
end

gear.register(jobs.JOB_WANDERER, rule)

return rule
