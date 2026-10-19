-- The Goblin gear handler override forces a club into the primary slot.
-- Example: spawning a Goblin through this overlay requests WPN_CLUB.

local items = require("ids.items")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Return a forced club loadout so the probe can distinguish a mod handler
-- from the goblin's normal source equipment distribution.
function handler.loadout()
    return {
        primary = {
            kind_id = items.WPN_CLUB,
            quality = {
                plus = 0,
                ego = "",
            },
        },
    }
end

registry.register(monsters.MONS_GOBLIN, handler.loadout)

return handler
