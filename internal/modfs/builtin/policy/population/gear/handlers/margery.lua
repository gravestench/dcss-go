-- Margery shares Wyrmbane with Maggie but carries a stronger source
-- enchantment. Her ordinary polearm or demon weapon remains the fallback.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- A winning roll gives +10 or +11 Wyrmbane. The extra plus draw occurs
-- only after the chance wins and the shared unique history is still free.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_MARGERY, depth) or {}

    if gear.chance_unique(ctx, artefacts.UNRAND_WYRMBANE, 100) then
        loadout.primary = {
            unique_id = artefacts.UNRAND_WYRMBANE,
            plus = 10 + gear.draw(ctx, 2),
        }
    end

    return loadout
end

registry.register(monsters.MONS_MARGERY, handler.loadout)

return handler
