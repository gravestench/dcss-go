-- Theory of operation: a primary Vaults hook creates one dense level grid,
-- chooses its source depth-based wall material, paints its defining motif,
-- then hands the result to the shared stair and population stages.
local grid = require("policy.generation.grid")
local geometry = require("policy.generation.layouts.vaults.geometry")
local population = require("policy.generation.layouts.vaults.population")

local build = {}

-- Keep layout hooks short: DES owns selection metadata, the motif owner
-- paints terrain, and this shared method owns one generation transaction.
function build.run(api, paint)
    local builder = grid.new(api.ctx)
    local wall = geometry.theme(builder, api.depth)

    paint(builder, wall)

    local records, room_ids, protected, room_entries =
        population.run(api, builder)

    if builder.bad_random then
        error(api.definition.id .. " exhausted its bounded layout random draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        records = records,
        room_ids = room_ids,
        room_entries = room_entries,
        protected = protected,
    }
end

return build
