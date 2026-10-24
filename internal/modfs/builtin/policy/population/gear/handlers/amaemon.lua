-- Amaemon's venomous demon whip remains ordinary on most spawns. The rare
-- Snakebite grant replaces that same weapon slot without duplicating stats.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Roll the source chance after the catalogued whip choice so a claimed
-- Snakebite leaves Amaemon armed with its ordinary fallback.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_AMAEMON, depth) or {}

    if gear.chance_unique(ctx, artefacts.UNRAND_SNAKEBITE, 100) then
        loadout.primary = {
            unique_id = artefacts.UNRAND_SNAKEBITE,
        }
    end

    return loadout
end

registry.register(monsters.MONS_AMAEMON, handler.loadout)

return handler
