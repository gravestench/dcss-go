-- The middle pair of this route is the hard choice: both chambers
-- shift together between first and second tier. The final pair stays
-- second tier and guards the approach to the exit.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")
local gauntlet = require("constants.gauntlet")

local module = {}

-- Place the opening pair before the source's later difficulty draw.
function module.opening(api)
    local extra_items = nil

    shared.setup(api, "DFJLNP", "EHKMOQ")

    shared.arena(api, "a", "gauntlet_arena_first", extra_items)
    shared.arena(api, "p", "gauntlet_arena_first", extra_items)
end

-- Choose q and r together only after both first-tier rooms exist.
function module.finish(api)
    local extra_items = nil

    if not api:has_placed_tag(gauntlet.FIRST_TIER_TAG) then
        error("hard-choice Gauntlet drew its tier before opening rooms")
    end

    if api:coinflip() then
        shared.arena(api, "q", "gauntlet_arena_first", extra_items)
        shared.arena(api, "r", "gauntlet_arena_first", extra_items)
    else
        shared.arena(api, "q", "gauntlet_arena_second", extra_items)
        shared.arena(api, "r", "gauntlet_arena_second", extra_items)
    end

    shared.arena(api, "s", "gauntlet_arena_second", extra_items)
    shared.arena(api, "u", "gauntlet_arena_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
