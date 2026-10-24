-- Theory of operation: one invocation turns nearby eligible walls into
-- saved temporary slimy walls. The existing wall-exposure policy supplies
-- acid damage and Jiyva immunity while these markers remain active.
local abilities = require("ids.abilities")
local component = require("constants.component")
local powers = require("policy.religion.jiyva.powers")
local temporary = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")
local time = require("constants.time")

local oozemancy = {}
local RADIUS = 4

-- The source FFT_WALL set excludes trees, arches, statues, and doors.
-- Permanent rock and preexisting slime walls cannot be transformed.
local eligible_walls = {
    [terrain.DNGN_METAL_WALL] = true,
    [terrain.DNGN_CRYSTAL_WALL] = true,
    [terrain.DNGN_ROCK_WALL] = true,
    [terrain.DNGN_STONE_WALL] = true,
    [terrain.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain.DNGN_CLEAR_STONE_WALL] = true,
}

-- Temporary terrain already owns a cell until its first effect expires.
-- A dry-run candidate check must agree with temporary.place at commitment.
local function occupied_cells(ctx, level_id)
    local occupied = {}

    for _, marker in ipairs(ctx:query({
        component.TEMPORARY_TERRAIN,
    })) do
        local state = ctx:get(marker, component.TEMPORARY_TERRAIN)

        if state.level_id == level_id then
            occupied[state.y .. ":" .. state.x] = true
        end
    end

    return occupied
end

-- The source uses a no-transparency radius, so a wall hidden behind
-- another wall is not reached simply because it is four cells away.
function oozemancy.walls(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local result = {}

    if not origin then
        return result
    end

    local occupied = occupied_cells(ctx, origin.level_id)

    for y = origin.y - RADIUS, origin.y + RADIUS do
        for x = origin.x - RADIUS, origin.x + RADIUS do
            local feature = ctx:cell(origin.level_id, x, y)
            local key = y .. ":" .. x

            if eligible_walls[feature] and not occupied[key] and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, RADIUS, x, y) then
                result[#result + 1] = {
                    x = x,
                    y = y,
                    level_id = origin.level_id,
                }
            end
        end
    end

    return result
end

-- Each saved marker carries this ability ID so abandonment can restore
-- these walls without touching temporary terrain from other powers.
function oozemancy.place(ctx, player, walls, turns)
    local made = 0

    for _, wall in ipairs(walls) do
        if temporary.place(ctx, player,
            abilities.JIYVA_OOZEMANCY,
            wall.level_id, wall.x, wall.y,
            terrain.DNGN_SLIMY_WALL,
            turns * time.AUT_PER_TURN) then
            made = made + 1
        end
    end

    if made > 0 then
        powers.start_oozemancy(ctx, player, walls[1].level_id, turns)
    end

    return made
end

return oozemancy
