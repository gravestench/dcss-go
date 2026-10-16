local items = require("ids.items")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

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
