-- Geryon carries the Horn as a real, unequipped inventory item. The
-- generic death drop then leaves it on the floor for the player.
local gear = require("policy.population.gear")
local items = require("ids.items")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Preserve any ordinary source gear and add the one forced miscellaneous
-- item. This mirrors mon-gear.cc rather than fabricating a death reward.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_GERYON, depth) or {}

    loadout.misc = {
        kind_id = items.MISC_HORN_OF_GERYON,
    }

    return loadout
end

registry.register(monsters.MONS_GERYON, handler.loadout)

return handler
