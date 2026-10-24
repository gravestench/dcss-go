-- Arachne always carries a poison staff unless the one-in-100 Olgreb roll
-- succeeds. Both occupy the monster weapon slot and become death loot.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local item_ids = require("ids.items")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Select the source staff kind here; the factory and shared staff profile
-- handle ECS possession, melee, and save validation.
function handler.loadout(ctx)
    local primary = {
        kind_id = item_ids.STAFF_POISON,
    }

    if gear.chance_unique(ctx, artefacts.UNRAND_OLGREB, 100) then
        primary = {
            unique_id = artefacts.UNRAND_OLGREB,
        }
    end

    return {
        primary = primary,
    }
end

registry.register(monsters.MONS_ARACHNE, handler.loadout)

return handler
