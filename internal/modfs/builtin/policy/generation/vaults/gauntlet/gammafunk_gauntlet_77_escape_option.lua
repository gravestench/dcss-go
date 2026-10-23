-- This compact 7x7 route lets the q chamber become a first or second
-- tier arena. The same coin flip changes the later prize pattern, so
-- the decision and its extra_items value stay local to this one map.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")
local gauntlet = require("constants.gauntlet")

local module = {}

-- Give the opening rooms their source prize pattern before the tier draw.
function module.opening(api)
    local extra_items = "fg**||...... / ."

    shared.setup(api, "DFJLN", "EHKMO")

    shared.arena(api, "a", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "p", "gauntlet_arena_77_first", extra_items)
end

-- The late prize pattern is local to this phase, so it cannot rewrite
-- the earlier child settings or leak into another floor generation.
function module.finish(api)
    local extra_items = "fg**||...... / ."

    if not api:has_placed_tag(gauntlet.FIRST_TIER_77_TAG) then
        error("escape-option Gauntlet drew its tier before opening rooms")
    end

    if api:coinflip() then
        shared.arena(api, "q", "gauntlet_arena_77_first", extra_items)
        extra_items = "fg|* / ."
    else
        extra_items = "fg|* / ."
        shared.arena(api, "q", "gauntlet_arena_77_second", extra_items)
    end

    shared.arena(api, "r", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "s", "gauntlet_arena_77_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
