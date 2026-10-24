-- Gastronok's hat can be the one-in-ten Pondering artefact. A miss still
-- gives him a good-quality ordinary hat, mapped to monster body armour.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local item_ids = require("ids.items")
local monsters = require("ids.monsters")
local quality = require("constants.vault_item_quality")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Keep quality generation on the factory's item path so the ordinary
-- fallback receives source good-item enchantment rather than a fixed plus.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_GASTRONOK, depth) or {}

    if gear.chance_unique(ctx, artefacts.UNRAND_PONDERING, 10) then
        loadout.body = {
            unique_id = artefacts.UNRAND_PONDERING,
        }
    else
        loadout.body = {
            kind_id = item_ids.ARM_HAT,
            generation_quality = quality.GOOD,
        }
    end

    return loadout
end

registry.register(monsters.MONS_GASTRONOK, handler.loadout)

return handler
