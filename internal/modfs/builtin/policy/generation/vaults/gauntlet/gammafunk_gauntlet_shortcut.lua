-- The shortcut offers two early second-tier arenas with sparse
-- prizes, or a longer sequence of first-tier arenas with richer
-- item patterns. The extra_items string is scoped to each segment.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")

local module = {}

-- Change the prize pattern at the route split before placing
-- each segment; one arena's custom pattern must not leak to another.
function module.compose(api)
    local extra_items = nil

    shared.setup(api, "DFJLNP", "EHKMOQ")

    extra_items = "fg / |* / e."
    shared.arena(api, "a", "gauntlet_arena_second", extra_items)
    shared.arena(api, "d", "gauntlet_arena_second", extra_items)
    extra_items = "fffggg|||***.... / ."
    shared.arena(api, "e", "gauntlet_arena_first", extra_items)
    shared.arena(api, "f", "gauntlet_arena_first", extra_items)
    shared.arena(api, "g", "gauntlet_arena_first", extra_items)
    shared.arena(api, "h", "gauntlet_arena_first", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
