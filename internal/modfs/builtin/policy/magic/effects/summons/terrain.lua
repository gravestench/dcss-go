local terrain_ids = require("constants.terrain")
local terrain = {}

function terrain.adjacent_solid(ctx, level_id, x, y)
    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local feature = ctx:cell(level_id, x + dx, y + dy)

                if not feature or not ctx:walkable(level_id, x + dx, y + dy) then
                    return true
                end
            end
        end
    end

    return false
end

-- Source: spl-summoning.cc:find_gateway_location. Forest ponds use the
-- same suitable locations as Malign Gateway.
function terrain.gateway_points(ctx, position)
    local points = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                for distance = 2, 12 do
                    local x = position.x + dx * distance
                    local y = position.y + dy * distance
                    local feature = ctx:cell(position.level_id, x, y)

                    if (feature == terrain_ids.DNGN_FLOOR or
                        feature == terrain_ids.DNGN_SHALLOW_WATER) and
                        not ctx:actor_at(position.level_id, x, y) and
                        not terrain.adjacent_solid(ctx, position.level_id, x, y) and
                        ctx:visible(position.level_id, position.x, position.y,
                            7, x, y) then
                        points[#points + 1] = { x = x, y = y }
                    end
                end
            end
        end
    end

    return points
end

return terrain
