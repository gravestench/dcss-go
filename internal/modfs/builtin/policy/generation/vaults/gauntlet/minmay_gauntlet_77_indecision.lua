-- Six 7x7 chambers create the indecision route: four first-tier
-- alternatives precede two second-tier choices. The parent geometry
-- defines which doors a player can reach before committing.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")

local module = {}

-- Match the six small chamber slots to their fixed source tiers,
-- then attach the minotaur exit behind the route.
function module.compose(api)
    local extra_items = nil

    shared.setup(api, "DFJLNP", "EHKMOQ")

    shared.arena(api, "a", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "p", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "q", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "r", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "s", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "u", "gauntlet_arena_77_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
