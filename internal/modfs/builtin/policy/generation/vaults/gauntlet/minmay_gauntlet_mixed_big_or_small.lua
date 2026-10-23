-- This route alternates large and 7x7 chambers in each tier.
-- Distinct tags matter: a small helper must fit the parent slot
-- without stretching its source MAP or changing item locations.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")

local module = {}

-- Alternate large and compact helpers as declared by the parent,
-- keeping tier and helper size independent choices.
function module.compose(api)
    local extra_items = nil

    shared.setup(api, "DFJLNP", "EHKMOQ")

    shared.arena(api, "a", "gauntlet_arena_first", extra_items)
    shared.arena(api, "p", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "q", "gauntlet_arena_first", extra_items)
    shared.arena(api, "r", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "s", "gauntlet_arena_second", extra_items)
    shared.arena(api, "u", "gauntlet_arena_77_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
