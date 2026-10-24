-- Theory of operation: one Abyss visit owns a moving 80x70 window and a
-- serializable source state. This generator plans the next region in Lua;
-- the game publishes both only after the region transaction succeeds.
local branches = require("ids.branches")
local constants = require("constants.abyss")
local terrain = require("constants.terrain")
local window = require("policy.generation.abyss.terrain")
local vaults = require("policy.generation.abyss.vaults")
local paths = require("policy.generation.abyss.paths")
local proto = require("policy.generation.abyss.proto")
local transporters = require("policy.generation.transporters")

local abyss = {}

-- Keep a level owner ready without selecting a borrowed floor or
-- consuming any Abyss RNG before the first actual entry. The first
-- region transaction replaces this neutral storage in one commit.
function abyss.storage(level_id)
    local cells = {}

    for y = 0, constants.HEIGHT - 1 do
        local row = {}

        for x = 0, constants.WIDTH - 1 do
            local boundary = x == 0 or y == 0 or
                x == constants.WIDTH - 1 or
                y == constants.HEIGHT - 1

            row[x + 1] = boundary and terrain.DNGN_ROCK_WALL or
                terrain.DNGN_FLOOR
        end

        cells[y + 1] = row
    end

    return {
        id = level_id or constants.LEVEL_ID,
        branch_id = branches.BRANCH_ABYSS,
        local_depth = 1,
        cells = cells,
        stairs = {},
        entry_x = constants.CENTRE_X,
        entry_y = constants.CENTRE_Y,
        initial_monsters = 0,
    }
end

-- Actors awaiting a source-style return remain ordinary ECS actors on a
-- separate, inert grid. The visible window can then be replaced without
-- serializing a second, partial copy of their health, AI, or equipment.
function abyss.transit_storage()
    return abyss.storage(constants.TRANSIT_LEVEL_ID)
end

-- Source proto generation samples the current world window, fits authored
-- vaults, then copies a faded impression of the departure floor into cells
-- those vaults did not claim. Exit and stair placement follows that imprint.
function abyss.generate(ctx, state, departure)
    if not state then
        error("Abyss generation requires saved procedural state")
    end

    local cells, updated = window.build(ctx, state)
    local records
    local ids
    local protected

    -- Source proto generation places authored furniture before its final
    -- safety pass. The center is cleared only after map terrain resolves.
    cells, records, ids, protected = vaults.fill(ctx, cells, updated)
    cells = proto.apply(ctx, cells, departure, protected)
    local path_records
    local path_ids

    cells, path_records, path_ids, protected = paths.place(ctx, cells,
        updated, protected)

    for _, record in ipairs(path_records) do
        records[#records + 1] = record
    end

    for _, id in ipairs(path_ids) do
        ids[#ids + 1] = id
    end
    updated.selected_map_ids = ids
    local center_x = constants.CENTRE_X
    local center_y = constants.CENTRE_Y

    -- Ordinary banishment always lands on floor; the pocket start's
    -- explicit exit feature will be installed by its entry policy.
    cells[center_y + 1][center_x + 1] = terrain.DNGN_FLOOR

    local level = {
        id = constants.LEVEL_ID,
        branch_id = branches.BRANCH_ABYSS,
        local_depth = updated.branch_depth,
        cells = cells,
        stairs = {},
        entry_x = center_x,
        entry_y = center_y,
        initial_monsters = 0,
        vault_ids = ids,
        vault_records = records,
        actor_moves = {},
        actor_retire = {},
    }

    -- Tagged exit and rune maps can contain named transporter pairs.
    -- Resolve them after every map has been placed so saved links point
    -- at the final destination coordinates in this Abyss window.
    transporters.resolve(level)

    return level, updated, protected
end

return abyss
