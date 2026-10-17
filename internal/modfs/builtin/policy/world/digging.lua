local terrain = require("constants.terrain")
local trajectory = require("policy.combat.trajectory")

local digging = {}

-- terrain.cc:feat_is_diggable. Both player and monster rays use these
-- intrinsic features; vault destruction vetoes need their own marker rule.
local diggable = {
    [terrain.DNGN_ROCK_WALL] = true,
    [terrain.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain.DNGN_SLIMY_WALL] = true,
    [terrain.DNGN_GRATE] = true,
    [terrain.DNGN_ORCISH_IDOL] = true,
    [terrain.DNGN_GRANITE_STATUE] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
}

function digging.first_wall(ctx, level_id, from_x, from_y,
    aim_x, aim_y, reach)
    local ray = trajectory.trace(ctx, level_id,
        from_x, from_y, aim_x, aim_y, reach)

    if not ray.blocked then
        return nil
    end

    return {
        x = ray.blocked_x,
        y = ray.blocked_y,
        feature = ctx:cell(level_id, ray.blocked_x, ray.blocked_y),
    }
end

function digging.can_break(feature)
    return diggable[feature] == true
end

-- A destroyed wall makes the next obstructing cell visible to the same
-- trajectory. Re-tracing preserves its grid tie breaks without cloning it.
function digging.ray(ctx, level_id, from_x, from_y,
    aim_x, aim_y, reach)
    local changed = 0

    for _ = 1, reach do
        local wall = digging.first_wall(ctx, level_id,
            from_x, from_y, aim_x, aim_y, reach)

        if not wall or not digging.can_break(wall.feature) then
            break
        end

        ctx:set_cell(level_id, wall.x, wall.y, terrain.DNGN_FLOOR)
        changed = changed + 1
    end

    return changed
end

return digging
