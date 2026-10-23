-- Source acquire.cc chooses a usable throwing subtype before generating
-- its stack. This picker is shared by direct god gifts and future direct
-- acquirement calls; ordinary floor missile weights are a different table.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local ids = require("ids.items")
local size = require("constants.size")
local source = require("policy.item_generation.source_roll")

local missiles = {}

-- Boomerangs and darts fit everyone. Medium bodies can throw javelins;
-- only large bodies can use large rocks under the source species rule.
function missiles.pick(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local rank = size.rank[species.size]
    local rows = {
        {
            id = ids.MI_BOOMERANG,
            weight = 50,
        },
        {
            id = ids.MI_DART,
            weight = 75,
        },
    }

    if rank >= size.rank[size.MEDIUM] then
        rows[#rows + 1] = {
            id = ids.MI_JAVELIN,
            weight = 100,
        }
    end

    if rank >= size.rank[size.LARGE] then
        rows[#rows + 1] = {
            id = ids.MI_LARGE_ROCK,
            weight = 100,
        }
    end

    return source.weighted_id(ctx, rows)
end

return missiles
