-- The Enchantress always wears the faerie dragon scales. The body slot
-- routes armour through ordinary equipment, death drops, and save rules.
local artefacts = require("ids.artefacts")
local monsters = require("ids.monsters")
local gear = require("policy.population.gear")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Roll the source weapon first, then grant unconditional armour without
-- consuming another gear draw. The special handler replaces only the
-- catalogue's missing body field, not its weapon rules.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_THE_ENCHANTRESS, depth) or {}

    loadout.body = {
        unique_id = artefacts.UNRAND_FAERIE,
    }

    return loadout
end

registry.register(monsters.MONS_THE_ENCHANTRESS, handler.loadout)

return handler
