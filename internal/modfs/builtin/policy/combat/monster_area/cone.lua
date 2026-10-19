-- Glaciate uses DCSS's 90-degree cone rather than a round blast. Rotate
-- the aimed vector by 45 degrees on each side, then keep visible cells
-- between those integer boundary rays in successive distance rings.
-- Source: target.cc:targeter_cone::set_aim.
-- Example: an eastward cast includes northeast and southeast cells but
-- excludes cells directly north or south of the caster.
local cone = {}
local SIGHT_RADIUS = 7
local HALF_ARC = math.pi / 4

-- The source adds one half before conversion to coord_def, whose integer
-- conversion truncates toward zero even for negative rotated coordinates.
local function source_round(origin, value)
    return math.modf(origin + value + 0.5) - origin
end

-- A nonnegative cross product puts the second ray to the left of the
-- first, including cells exactly on a boundary.
local function left_or_on(first, second)
    return first.x * second.y >= first.y * second.x
end

-- Preserve the source boundary rounding and LOS_NO_TRANS. Result order is
-- by distance ring and coordinate, independent of Lua table traversal.
function cone.cells(ctx, level_id, origin_x, origin_y,
    aim_x, aim_y, range)
    local dx = aim_x - origin_x
    local dy = aim_y - origin_y

    if dx == 0 and dy == 0 then
        return {}
    end

    local cosine = math.cos(HALF_ARC)
    local sine = math.sin(HALF_ARC)
    local left = {
        x = source_round(origin_x, cosine * dx + sine * dy),
        y = source_round(origin_y, -sine * dx + cosine * dy),
    }
    local right = {
        x = source_round(origin_x, cosine * dx - sine * dy),
        y = source_round(origin_y, sine * dx + cosine * dy),
    }

    if not left_or_on(left, right) then
        left, right = right, left
    end

    local cells = {}

    for ring = 1, range do
        for x = -ring, ring do
            for y = -ring, ring do
                if math.max(math.abs(x), math.abs(y)) == ring then
                    local offset = {
                        x = x,
                        y = y,
                    }
                    local cell_x = origin_x + x
                    local cell_y = origin_y + y

                    if left_or_on(left, offset) and
                        left_or_on(offset, right) and
                        ctx:cell(level_id, cell_x, cell_y) and
                        ctx:visible_no_trans(level_id,
                            origin_x, origin_y, SIGHT_RADIUS,
                            cell_x, cell_y) then
                        cells[#cells + 1] = {
                            level_id = level_id,
                            x = cell_x,
                            y = cell_y,
                            ring = ring,
                        }
                    end
                end
            end
        end
    end

    return cells
end

return cone
