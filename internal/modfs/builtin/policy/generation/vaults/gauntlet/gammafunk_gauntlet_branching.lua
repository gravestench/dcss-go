-- This wide branching route opens with two first-tier arenas. One
-- coin flip assigns the middle four chambers a shared difficulty;
-- the two final chambers remain second-tier in either outcome.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")
local gauntlet = require("constants.gauntlet")

local module = {}

-- The first hook must finish placing a and d before the later hook draws
-- their middle branch. DES runs these hooks at separate source positions.
function module.opening(api)
    local extra_items = nil

    shared.setup(api, "DFJLNPRp", "EHKMOQSq")

    shared.arena(api, "a", "gauntlet_arena_first", extra_items)
    shared.arena(api, "d", "gauntlet_arena_first", extra_items)
end

-- Apply the middle branch's tier as one choice after the opening rooms.
function module.finish(api)
    local extra_items = nil

    if not api:has_placed_tag(gauntlet.FIRST_TIER_TAG) then
        error("branching Gauntlet drew its middle tier before opening rooms")
    end

    if api:coinflip() then
        shared.arena(api, "e", "gauntlet_arena_first", extra_items)
        shared.arena(api, "f", "gauntlet_arena_first", extra_items)
        shared.arena(api, "g", "gauntlet_arena_first", extra_items)
        shared.arena(api, "h", "gauntlet_arena_first", extra_items)
    else
        shared.arena(api, "e", "gauntlet_arena_second", extra_items)
        shared.arena(api, "f", "gauntlet_arena_second", extra_items)
        shared.arena(api, "g", "gauntlet_arena_second", extra_items)
        shared.arena(api, "h", "gauntlet_arena_second", extra_items)
    end

    shared.arena(api, "i", "gauntlet_arena_second", extra_items)
    shared.arena(api, "j", "gauntlet_arena_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
