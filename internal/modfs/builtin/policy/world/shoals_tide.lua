-- Shoals water follows an authored elevation map and a shared tide clock.
-- DCSS stores elevation separately from visible floor/water for this reason:
-- a wet square must remember how high its coast was when the sea recedes.
local terrain = require("constants.terrain")

local tide = {}

local LOW = -36
local HIGH = 50
local DECEL_MARGIN = 8
local CALL_VELOCITY = 21
local PEAK_VELOCITY = 2
local MULTIPLIER = 2
local CALL_RADIUS = 8
local CALLED_PEAK = 50
local AUT_PER_TURN = 10

-- The source accelerates through the middle of its range and slows at both
-- ends. A caller overrides the velocity for that step, producing a surge.
function tide.advance(height, velocity, called)
    if called then
        velocity = CALL_VELOCITY
    elseif math.abs(velocity) > PEAK_VELOCITY then
        velocity = -PEAK_VELOCITY
    end

    height = math.max(LOW, math.min(HIGH, height + velocity))

    if height == HIGH and velocity > 0 or
        height == LOW and velocity < 0 then
        velocity = -velocity
    end

    local near_end = math.abs(height - HIGH) < DECEL_MARGIN or
        math.abs(height - LOW) < DECEL_MARGIN

    if (math.abs(velocity) > 1) == near_end then
        if near_end then
            -- C++ integer division truncates toward zero, including a
            -- falling negative velocity.
            if velocity < 0 then
                velocity = math.ceil(velocity / 2)
            else
                velocity = math.floor(velocity / 2)
            end
        else
            velocity = velocity * 2
        end
    end

    return height, velocity
end

-- The local call is strongest at its caster and weakens by three height
-- units per tile. It is layered over the ordinary Shoals tide.
function tide.at(base_height, x, y, caller, elapsed_turns)
    if not caller then
        return base_height
    end

    local distance = math.max(math.abs(x - caller.x),
        math.abs(y - caller.y))

    if distance > CALL_RADIUS then
        return base_height
    end

    local peak = math.min(CALLED_PEAK,
        math.max(1, elapsed_turns) * 5)

    return base_height + math.max(0, peak - distance * 3)
end

-- Only visible floor and shallow water alternate as the shoreline moves.
local function susceptible(feature)
    return feature == terrain.DNGN_FLOOR or
        feature == terrain.DNGN_SHALLOW_WATER
end

-- Deep water is a sea conduit even though the tide cannot convert it.
local function watery(feature)
    return feature == terrain.DNGN_SHALLOW_WATER or
        feature == terrain.DNGN_DEEP_WATER or
        feature == terrain.DNGN_OPEN_SEA
end

-- Water propagates from existing sea and through open doors. A closed door
-- lets a wave through only sometimes, as in the source Shoals traversal.
-- Doors can let a wave pass, but a closed one requires a source RNG roll.
local function passable(ctx, feature)
    if watery(feature) or feature == terrain.DNGN_OPEN_DOOR or
        feature == terrain.DNGN_OPEN_CLEAR_DOOR then
        return true
    end

    if feature == terrain.DNGN_CLOSED_DOOR or
        feature == terrain.DNGN_CLOSED_CLEAR_DOOR then
        return ctx:random("shoals_tide", 3) == 0
    end

    return false
end

-- The authored elevation determines the feature after the current water
-- level is subtracted; the tide never creates deep water or new walls.
local function desired_feature(ctx, level_id, x, y, height)
    local elevation = ctx:shoals_height(level_id, x, y)

    if elevation == nil then
        return nil
    end

    if elevation - height < 0 then
        return terrain.DNGN_SHALLOW_WATER
    end

    return terrain.DNGN_FLOOR
end

-- The source starts its flood traversal at four near-corner sea cells and
-- at vault markers named tide_seed. The queue only crosses cells that were
-- already wet, so an inland isolated pool cannot inundate a sealed room.
function tide.apply(ctx, level_id, raw_height, caller, elapsed_turns,
    rising)
    local width, height = ctx:level_size(level_id)

    if not width or not height then
        return
    end

    local queue = {}
    local seen = {}

    -- Marking at enqueue time prevents two neighboring waves from causing
    -- duplicate visits or order-dependent extra RNG draws.
    local function enqueue(x, y)
        if x < 0 or y < 0 or x >= width or y >= height then
            return
        end

        local key = y * width + x

        if seen[key] then
            return
        end

        seen[key] = true
        queue[#queue + 1] = { x = x, y = y }
    end

    enqueue(1, 1)
    enqueue(width - 2, 1)
    enqueue(1, height - 2)
    enqueue(width - 2, height - 2)

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if ctx:marker_property(level_id, x, y, "tide_seed") == "y" then
                enqueue(x, y)
            end
        end
    end

    local cursor = 1

    while cursor <= #queue do
        local cell = queue[cursor]
        local old = ctx:cell(level_id, cell.x, cell.y)
        local was_wet = passable(ctx, old)

        cursor = cursor + 1

        if susceptible(old) then
            local local_height = tide.at(math.floor(raw_height / MULTIPLIER),
                cell.x, cell.y, caller, elapsed_turns)
            local desired = desired_feature(ctx, level_id,
                cell.x, cell.y, local_height)

            if desired and desired ~= old and
                (rising and desired == terrain.DNGN_SHALLOW_WATER or
                not rising and desired == terrain.DNGN_FLOOR) then
                ctx:set_cell(level_id, cell.x, cell.y, desired)
            end
        end

        local still_wet = watery(ctx:cell(level_id, cell.x, cell.y))

        if was_wet and (still_wet or ctx:random("shoals_tide", 2) == 0) then
            for dy = -1, 1 do
                for dx = -1, 1 do
                    if dx ~= 0 or dy ~= 0 then
                        local x = cell.x + dx
                        local y = cell.y + dy
                        local feature = ctx:cell(level_id, x, y)

                        if feature and
                            (susceptible(feature) or passable(ctx, feature)) then
                            enqueue(x, y)
                        end
                    end
                end
            end
        end
    end
end

return tide
