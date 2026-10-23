-- This long route has three first-tier chambers followed by six
-- second-tier chambers. There is no tier coin flip, which makes
-- authored arena order the meaningful source decision.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")

local module = {}

-- Place the nine named stations in route order before adding the
-- guarded exit and the shared floor appearance rules.
function module.compose(api)
    local extra_items = nil

    shared.setup(api, "DFJLNPRpr", "EHKMOQSqs")

    shared.arena(api, "a", "gauntlet_arena_first", extra_items)
    shared.arena(api, "d", "gauntlet_arena_first", extra_items)
    shared.arena(api, "e", "gauntlet_arena_first", extra_items)
    shared.arena(api, "f", "gauntlet_arena_second", extra_items)
    shared.arena(api, "g", "gauntlet_arena_second", extra_items)
    shared.arena(api, "h", "gauntlet_arena_second", extra_items)
    shared.arena(api, "i", "gauntlet_arena_second", extra_items)
    shared.arena(api, "j", "gauntlet_arena_second", extra_items)
    shared.arena(api, "k", "gauntlet_arena_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
