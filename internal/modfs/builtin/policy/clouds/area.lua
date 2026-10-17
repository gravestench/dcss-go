local placement = require("policy.clouds.placement")
local component = require("constants.component")
local spell_range = require("constants.spell_range")

local area = {}

local directions = {
    { x = -1, y = -1 },
    { x = 0, y = -1 },
    { x = 1, y = -1 },
    { x = -1, y = 0 },
    { x = 1, y = 0 },
    { x = -1, y = 1 },
    { x = 0, y = 1 },
    { x = 1, y = 1 },
}

local function key(x, y)
    return x .. ":" .. y
end

local function duration(ctx, power, stream)
    local spread = math.floor(power / 4)
    local turns = 3

    if spread > 0 then
        for _ = 1, 3 do
            turns = turns + ctx:random(stream, spread)
        end
    end

    return turns * 10
end

local function shuffle(ctx, cells, stream)
    for index = #cells, 2, -1 do
        local other = 1 + ctx:random(stream, index)

        cells[index], cells[other] = cells[other], cells[index]
    end
end

local function cloudable(ctx, viewer, level_id, x, y)
    return ctx:walkable(level_id, x, y) and
        not placement.at(ctx, level_id, x, y) and
        ctx:visible(level_id, viewer.x, viewer.y,
            spell_range.LOS_RADIUS, x, y)
end

local function player_viewer(ctx, level_id)
    local viewer = ctx:get(ctx:player(), component.POSITION)

    if not viewer or viewer.level_id ~= level_id then
        error("area cloud requires a player on the target level")
    end

    return viewer
end

local function expand(ctx, viewer, level_id, queue, seen)
    local next_ring = {}

    for _, cell in ipairs(queue) do
        for _, direction in ipairs(directions) do
            local next_x = cell.x + direction.x
            local next_y = cell.y + direction.y
            local id = key(next_x, next_y)

            if not seen[id] then
                seen[id] = true

                if cloudable(ctx, viewer, level_id,
                    next_x, next_y) then
                    next_ring[#next_ring + 1] = {
                        x = next_x,
                        y = next_y,
                    }
                end
            end
        end
    end

    return next_ring
end

-- Return the full last shell because source tracer marks possible cells
-- throughout a shell even when only some will be selected at resolution.
function area.candidates(ctx, level_id, x, y, count)
    local viewer = player_viewer(ctx, level_id)
    local queue = {
        { x = x, y = y },
    }
    local seen = { [key(x, y)] = true }
    local result = {}

    while #queue > 0 and #result < count do
        for _, cell in ipairs(queue) do
            result[#result + 1] = cell
        end

        queue = expand(ctx, viewer, level_id, queue, seen)
    end

    return result
end

-- Source: spl-util.cc:apply_area_cloud and spl-clouds.cc:big_cloud.
function area.place(ctx, kind_id, caster, level_id, x, y,
    power, count, stream)
    local viewer = player_viewer(ctx, level_id)

    local seen = { [key(x, y)] = true }
    local queue = {
        { x = x, y = y },
    }
    local placed = 0

    while #queue > 0 and placed < count do
        shuffle(ctx, queue, stream)

        for _, cell in ipairs(queue) do
            if placed < count and placement.place(ctx, kind_id, caster,
                level_id, cell.x, cell.y,
                duration(ctx, power, stream)) then
                placed = placed + 1
            end

        end

        queue = expand(ctx, viewer, level_id, queue, seen)
    end

    return placed
end

return area
