-- Theory of operation: one source CHANCE activates a cluster of ice maps.
-- Independent rolls favor four pieces, while a deep Dungeon cluster may
-- also request an Ice Cave entrance if an overlaid mod supplies that pool.
local branches = require("ids.branches")
local tags = require("constants.vault_tags")
local handler = {}

-- Check for an Ice Cave map before drawing its coinflip, matching the
-- source's map_by_tag guard and keeping RNG stable with no cave catalog.
local function place_ice(api)
    local count = 4 + api:roll(3) * api:roll(4)
    local cave_count = 0

    if api.context.branch_id == branches.BRANCH_DUNGEON and
        api:absolute_depth() >= 11 and api:has_tag(tags.UNIQ_ICECV) and
        api:chance(1, 2) then
        cave_count = 1
    end

    api:place_maps(tags.SERIAL_ICE, count)
    api:place_maps(tags.CHANCE_ICECAVE, cave_count)
end

handler.place_ice = place_ice

return handler
