-- This seven-chamber tree has three first-tier leaves and four
-- second-tier leaves. Using 7x7 helper tags preserves each branch's
-- compact geometry and prize positions.
-- The source MAP remains in the same-named DES file.
local shared = require("policy.generation.vaults.gauntlet.shared")

local module = {}

-- Fill the tree's named branches in authored order; transporter
-- names come from their parent ordinal rather than file load order.
function module.compose(api)
    local extra_items = nil

    shared.setup(api, "DFJLNPR", "EHKMOQS")

    shared.arena(api, "a", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "p", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "q", "gauntlet_arena_77_first", extra_items)
    shared.arena(api, "r", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "s", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "u", "gauntlet_arena_77_second", extra_items)
    shared.arena(api, "z", "gauntlet_arena_77_second", extra_items)
    shared.exit(api, "y")

    shared.appearance(api)
end

return module
