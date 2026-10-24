-- Terence rarely appears with Throatcutter. On every other roll he keeps
-- the source-weighted ordinary weapon from his imported monster catalog.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Ask the unique ledger after the chance draw so another source of
-- Throatcutter leaves Terence's normal weapon in place.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_TERENCE, depth) or {}

    if gear.chance_unique(ctx, artefacts.UNRAND_THROATCUTTER, 100) then
        loadout.primary = {
            unique_id = artefacts.UNRAND_THROATCUTTER,
        }
    end

    return loadout
end

registry.register(monsters.MONS_TERENCE, handler.loadout)

return handler
