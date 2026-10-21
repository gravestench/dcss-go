-- Test only: draw from a persisted stream, then return a valid shaped floor
-- under the wrong ID. The travel transaction must reject and undo the draw.
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local branches = require("ids.branches")

local vestibule = {}

-- This floor reaches Go's generic stage decoder and population path. Its
-- wrong level ID is a Hell contract error that save validation must catch
-- before the player moves, rather than leaving an unloadable session.
local function generate(ctx)
    ctx:random(streams.PLACEMENT, 4)

    local cells = {}

    for y = 1, 70 do
        local row = {}

        for x = 1, 80 do
            row[x] = terrain.DNGN_FLOOR
        end

        cells[y] = row
    end

    cells[36][41] = terrain.DNGN_EXIT_HELL

    return {
        level = {
            id = 9001,
            branch_id = branches.BRANCH_VESTIBULE,
            local_depth = 1,
            cells = cells,
            stairs = {},
            entry_x = 40,
            entry_y = 35,
            initial_monsters = 3,
            vault_id = "vestibule_of_hell_subvaulted",
            vault_ids = {},
        },
    }
end

vestibule.generate = generate

return vestibule
