-- A source LOS_SOLID radius sees walkable cells and the blocking surface
-- at the end of a ray. Blood may mark a visible wall even though actors
-- cannot occupy it; a wall behind another wall remains outside the area.
local trajectory = require("policy.combat.trajectory")

local area = {}

-- Keep the source square radius and solid ray in one owner so actor effects
-- and terrain markings agree on which coordinate the blessing reaches.
function area.contains(ctx, origin, point, radius)
    if point.level_id ~= origin.level_id then
        return false
    end

    local distance = math.max(math.abs(point.x - origin.x),
        math.abs(point.y - origin.y))

    if distance > radius then
        return false
    end

    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y, point.x, point.y, radius)

    return not ray.blocked or
        ray.blocked_x == point.x and ray.blocked_y == point.y
end

return area
