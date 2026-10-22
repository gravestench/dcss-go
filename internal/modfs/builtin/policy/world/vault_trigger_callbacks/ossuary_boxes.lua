-- Theory of operation: all ':' markers in the authored boxes Ossuary share
-- one saved group. Its trigger component carries links to every surviving
-- a/b wall record after map orientation. Any entry opens that whole set;
-- the generic trigger owner then consumes every sibling in one event.
local channels = require("constants.message_channels")
local terrain = require("constants.terrain")

local boxes = {}

-- A missing or changed wall is a broken source/save contract, not a cue
-- to open an unrelated cell. Already-open floor supports an idempotent
-- callback if a mod invokes it twice before group consumption.
local function open(ctx, state)
    if #state.wall_x == 0 or
        #state.wall_x ~= #state.wall_y or
        #state.wall_x ~= #state.wall_record_indices then
        error("Ossuary boxes have no complete wall record group")
    end

    for index, x in ipairs(state.wall_x) do
        local y = state.wall_y[index]
        local feature = ctx:cell(state.level_id, x, y)

        if feature ~= terrain.DNGN_STONE_WALL and
            feature ~= terrain.DNGN_FLOOR then
            error("Ossuary wall changed before its trigger fired")
        end
    end

    for index, x in ipairs(state.wall_x) do
        ctx:set_cell(state.level_id, x, state.wall_y[index],
            terrain.DNGN_FLOOR)
    end

    ctx:emit(channels.VAULT,
        "There is a click, and some walls slide away!")
end

boxes.open = open

return boxes
