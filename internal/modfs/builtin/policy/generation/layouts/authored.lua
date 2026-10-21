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
        prior_vault_ids = api.prior_vault_ids,
        branch_entries = api.branch_entries,
    }
    local placed = placement.place(nil, builder, api.definition, player)
    local protected = {}

    -- Later extra vaults cannot replace cells belonging to this whole-map
    -- layout or its nested helpers, including their typed source records.
    for _, point in ipairs(placed.occupied) do
        protected[point.x .. ":" .. point.y] = true
    end

    return {
        builder = builder,
        rows = builder:rows(),
        records = placed.records,
        vault_ids = placed.vault_ids,
        protected = protected,
        placement = placed,
    }
end

return authored
