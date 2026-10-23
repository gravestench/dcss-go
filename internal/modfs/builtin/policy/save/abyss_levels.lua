-- An unvisited Abyss owns a neutral backing grid; an active visit owns
-- sampled terrain and procedural state. The save policy checks branch
-- meaning while Go validates dense geometry and integer coordinates.
local constants = require("constants.abyss")
local terrain = require("constants.terrain")

local abyss = {}

-- An absent state means no visit has drawn a borrowed floor or advanced
-- the Abyss clock. Its storage grid must not contain an old fixed portal.
local function validate_storage(level)
    if level.local_depth ~= 1 or
        #level.stairs ~= 0 or
        level.initial_monsters ~= 0 or
        level.cells[constants.CENTRE_Y + 1][constants.CENTRE_X + 1] ~=
            terrain.DNGN_FLOOR then
        error("unvisited Abyss storage is invalid")
    end
end

-- Once visited, the saved branch depth and the grid's depth describe
-- the same moving region. Stair destination and rune invariants are
-- checked with the source travel policies when those records are loaded.
local function validate_active(level, state)
    if level.local_depth ~= state.branch_depth or
        state.branch_depth < 1 or
        state.branch_depth > 7 then
        error("active Abyss depth differs from procedural state")
    end
end

-- Validate one level through its own source role, never through an
-- assumed portal at the old fixed center.
function abyss.validate(level, state)
    if #level.cells ~= constants.HEIGHT or
        #level.cells[1] ~= constants.WIDTH then
        error("saved Abyss level has invalid geometry")
    end

    if state then
        validate_active(level, state)
    else
        validate_storage(level)
    end
end

-- The transit grid is deliberately boring: every interior cell remains
-- floor, and it never owns a stair or DES record. Only ECS actors use it.
function abyss.validate_transit(level)
    if level.id ~= constants.TRANSIT_LEVEL_ID or
        level.local_depth ~= 1 or
        #level.cells ~= constants.HEIGHT or
        #level.cells[1] ~= constants.WIDTH or
        #level.stairs ~= 0 or
        #level.vault_records ~= 0 or
        level.initial_monsters ~= 0 then
        error("Abyss transit storage has invalid metadata")
    end

    for y, row in ipairs(level.cells) do
        for x, feature in ipairs(row) do
            local boundary = x == 1 or y == 1 or
                x == constants.WIDTH or y == constants.HEIGHT
            local expected = boundary and terrain.DNGN_ROCK_WALL or
                terrain.DNGN_FLOOR

            if feature ~= expected then
                error("Abyss transit storage terrain changed")
            end
        end
    end
end

return abyss
