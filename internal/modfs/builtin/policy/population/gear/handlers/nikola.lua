-- Nikola normally wields his catalogued electric rapier. On a rare source
-- roll it is replaced by Arc Blade, which uses the ordinary unique ledger.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Keep the ordinary weapon as the miss or already-claimed fallback.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_NIKOLA, depth) or {}

    if gear.chance_unique(ctx, artefacts.UNRAND_ARC_BLADE, 100) then
        loadout.primary = {
            unique_id = artefacts.UNRAND_ARC_BLADE,
        }
    end

    return loadout
end

registry.register(monsters.MONS_NIKOLA, handler.loadout)

return handler
