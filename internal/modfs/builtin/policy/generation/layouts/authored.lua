-- Theory of operation: some source layouts are whole authored DES maps,
-- rather than scripts that carve a new grid. Place their MAP through the
-- same vault operation engine used by nested helpers. This preserves
-- SUBVAULT, substitutions, keyed effects, and source directive order.
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")

local authored = {}

-- Assemble one full level from its committed MAP. The layout catalog
-- adds ordinary stairs afterward and keeps the map's typed effects for
-- later population and save processing.
function authored.execute(api)
    local builder = grid.new(api.ctx)
    local player = {
        branch_id = api.branch_id,
        depth = api.depth,
        branch_bottom = api.branch_bottom,
        absolute_depth = api.absolute_depth,
    }
    local placed = placement.place(nil, builder, api.definition, player)

    return {
        builder = builder,
        rows = builder:rows(),
        records = placed.records,
    }
end

return authored
