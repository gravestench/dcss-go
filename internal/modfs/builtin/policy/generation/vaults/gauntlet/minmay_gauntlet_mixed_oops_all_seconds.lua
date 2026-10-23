-- Every arena on this mixed-size route is second tier, including
-- the first reachable chambers. The alternation changes geometry,
-- not difficulty or encounter selection.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")

local module = {}

-- Fill all six mixed-size slots with second-tier helpers before
-- adding the source exit and appearance instructions.
function module.compose(api)
    local extra_items = nil

    shared.setup(api, "DFJLNP", "EHKMOQ")

    shared.arena(api, "a", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "p", "gauntlet_arena_second", extra_items)
    shared.arena(api, "q", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "r", "gauntlet_arena_second", extra_items)
    shared.arena(api, "s", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "u", "gauntlet_arena_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
