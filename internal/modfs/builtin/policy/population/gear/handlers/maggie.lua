-- Maggie can carry Wyrmbane on a one-in-100 weapon roll. It shares one
-- saved unique claim with Margery, so whichever appears second falls back.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- The source raises Maggie's Wyrmbane item enchantment to +9 after the
-- unique is chosen; the underlying artefact catalog remains unchanged.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_MAGGIE, depth) or {}

    if gear.chance_unique(ctx, artefacts.UNRAND_WYRMBANE, 100) then
        loadout.primary = {
            unique_id = artefacts.UNRAND_WYRMBANE,
            plus = 9,
        }
    end

    return loadout
end

registry.register(monsters.MONS_MAGGIE, handler.loadout)

return handler
