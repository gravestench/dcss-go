-- Wind Blast shares one cone and outward-ray geometry for actors and
-- clouds. This module reads the grid; the callers own all mutations.
local trajectory = require("policy.combat.trajectory")

local geometry = {}

-- Source grid distance counts a diagonal step as one cell.
function geometry.distance(first, second)
    return math.max(math.abs(first.x - second.x),
        math.abs(first.y - second.y))
end

-- The cross/dot comparison is the source 45-degree cone without floating
-- point angle rounding. A zero aim means an untargeted full-circle blast.
function geometry.in_cone(source, aim, point)
    if not aim then
        return true
    end

    local aim_x = aim.x - source.x
    local aim_y = aim.y - source.y
    local point_x = point.x - source.x
    local point_y = point.y - source.y
    local dot = aim_x * point_x + aim_y * point_y
    local cross = aim_x * point_y - aim_y * point_x

    return dot > 0 and math.abs(cross) <= dot
end

-- LOS_SOLID ignores opaque clouds and transparent-looking wall rules;
-- only an actually solid cell stops the gale's ray to this point.
function geometry.visible_solid(ctx, source, point)
    local ray = trajectory.to_target(ctx, source.level_id,
        source.x, source.y, point.x, point.y, 7)

    return not ray.blocked and
        ray.x == point.x and ray.y == point.y
end

-- The source tracer continues beyond a struck cell. Return the next ray
-- cell even when that cell is solid, so callers can record a collision.
function geometry.next_cell(ctx, source, position)
    local ray = trajectory.trace(ctx, source.level_id,
        source.x, source.y, position.x, position.y, 7)

    for index, cell in ipairs(ray.path) do
        if cell.x == position.x and cell.y == position.y then
            return ray.path[index + 1] or
                (ray.blocked and {
                    x = ray.blocked_x,
                    y = ray.blocked_y,
                })
        end
    end

    return nil
end

-- When the ray is obstructed, DCSS tries cells at the same outward
-- distance. Actors scan around the blocked cell; clouds scan around their
-- current cell. Keep a stable order for deterministic saves.
function geometry.alternates(source, current, blocked, center)
    local cells = {}
    local target_distance = geometry.distance(source, blocked)
    local origin = center or blocked

    for dy = -1, 1 do
        for dx = -1, 1 do
            local cell = {
                x = origin.x + dx,
                y = origin.y + dy,
            }

            if (dx ~= 0 or dy ~= 0) and
                geometry.distance(current, cell) == 1 and
                geometry.distance(source, cell) == target_distance and
                (cell.x ~= source.x or cell.y ~= source.y) then
                cells[#cells + 1] = cell
            end
        end
    end

    return cells
end

return geometry
