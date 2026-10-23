-- Small 7x7 arenas surround a single larger choke-point chamber.
-- That central chamber draws its tier once; later small rooms stay
-- second tier regardless of the draw.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")
local gauntlet = require("constants.gauntlet")

local module = {}

-- Fill the small opening rooms before the central chamber's tier draw.
function module.opening(api)
    local extra_items = nil

    shared.setup(api, "DFJLNPR", "EHKMOQS")

    shared.arena(api, "a", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "p", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "q", "gauntlet_arena_77_first", extra_items)
end

-- Resolve the large r chamber after the opening rooms have placed.
function module.finish(api)
    local extra_items = nil

    if not api:has_placed_tag(gauntlet.FIRST_TIER_77_TAG) then
        error("choke-point Gauntlet drew its tier before opening rooms")
    end

    if api:coinflip() then
        shared.arena(api, "r", "gauntlet_arena_second", extra_items)
    else
        shared.arena(api, "r", "gauntlet_arena_first", extra_items)
    end

    shared.arena(api, "s", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "u", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "z", "gauntlet_arena_77_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
