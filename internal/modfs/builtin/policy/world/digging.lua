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

-- Trace only to the first obstruction so a later wall cannot be removed through an earlier one.
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

-- A ray may remove only catalogued diggable terrain; other obstruction ends the effect.
-- Example: digging.can_break(terrain.DNGN_ROCK_WALL) allows Dig's ray to continue through rock.
function digging.can_break(feature)
    return diggable[feature] == true
end

-- A destroyed wall makes the next obstructing cell visible to the same
-- trajectory. Re-tracing preserves its grid tie breaks without cloning it.
-- Return removed cells so callers can describe only destruction in view.
function digging.ray(ctx, level_id, from_x, from_y,
    aim_x, aim_y, reach)
    local changed = 0
    local removed = {}

    for _ = 1, reach do
        local wall = digging.first_wall(ctx, level_id,
            from_x, from_y, aim_x, aim_y, reach)

        if not wall or not digging.can_break(wall.feature) then
            break
        end

        ctx:set_cell(level_id, wall.x, wall.y, terrain.DNGN_FLOOR)
        changed = changed + 1
        removed[#removed + 1] = {
            level_id = level_id,
            x = wall.x,
            y = wall.y,
        }
    end

    return changed, removed
end

return digging
