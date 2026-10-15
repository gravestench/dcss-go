-- Trace a cell-centre projectile ray through the dense grid. This uses the
-- same tie-breaking geometry as Level.ClearProjectilePath. Contacts are
-- resolved in order by the attack policy: a miss keeps flying, while a hit
-- stops an ordinary missile. Shots continue past the cursor up to range.
local trajectory = {}

function trajectory.trace(ctx, level_id, from_x, from_y, to_x, to_y,
    range, stop_at_aim)
    local aim_x = to_x - from_x
    local aim_y = to_y - from_y

    if range and not stop_at_aim then
        to_x = from_x + aim_x * range
        to_y = from_y + aim_y * range
    end

    local dx = math.abs(to_x - from_x)
    local dy = math.abs(to_y - from_y)
    local step_x = to_x < from_x and -1 or 1
    local step_y = to_y < from_y and -1 or 1
    local x = from_x
    local y = from_y
    local steps_x = 0
    local steps_y = 0
    local actors = {}
    local contacts = {}
    local path = {}
    local travelled = 0

    while (steps_x < dx or steps_y < dy) and
        (not range or travelled < range) do
        local crossing = (1 + 2 * steps_x) * dy - (1 + 2 * steps_y) * dx
        local last_x = x
        local last_y = y

        if crossing <= 0 then
            x = x + step_x
            steps_x = steps_x + 1
        end

        if crossing >= 0 then
            y = y + step_y
            steps_y = steps_y + 1
        end

        travelled = travelled + 1

        if not ctx:walkable(level_id, x, y) then
            return {
                blocked = true,
                x = last_x,
                y = last_y,
                blocked_x = x,
                blocked_y = y,
                path = path,
                actors = actors,
                contacts = contacts,
            }
        end

        path[#path + 1] = {
            x = x,
            y = y,
        }

        local actor = ctx:actor_at(level_id, x, y)

        if actor then
            actors[#actors + 1] = actor
            contacts[#contacts + 1] = {
                actor = actor,
                x = x,
                y = y,
            }
        end
    end

    return {
        x = x,
        y = y,
        path = path,
        actors = actors,
        contacts = contacts,
    }
end

-- Explosion targeting and displacement stop at the selected cell instead
-- of projecting the cursor direction all the way to maximum spell range.
function trajectory.to_target(ctx, level_id, from_x, from_y,
    to_x, to_y, range)
    return trajectory.trace(ctx, level_id, from_x, from_y,
        to_x, to_y, range, true)
end

-- Electrical beams can reflect from a solid feature and revisit actors.
-- beam.cc:bounce charges two cells of range per reflection; ray.cc chooses
-- the reflected side from the solidity of the eight adjacent cells. This
-- discrete reflection follows the same wall/corner cases on cell-centre
-- rays. It does not model ray.cc's subcell diagonal-corridor zigzag.
function trajectory.bouncing(ctx, level_id, from_x, from_y,
    to_x, to_y, range, can_bounce)
    local result = {
        x = from_x,
        y = from_y,
        path = {},
        actors = {},
        contacts = {},
        bounces = 0,
    }
    local x, y = from_x, from_y
    local aim_x = to_x - from_x
    local aim_y = to_y - from_y
    local remaining = range

    while remaining > 0 and (aim_x ~= 0 or aim_y ~= 0) do
        local segment = trajectory.trace(ctx, level_id, x, y,
            x + aim_x, y + aim_y, remaining)

        for _, cell in ipairs(segment.path) do
            result.path[#result.path + 1] = cell
        end
        for _, actor in ipairs(segment.actors) do
            result.actors[#result.actors + 1] = actor
        end
        for _, contact in ipairs(segment.contacts) do
            result.contacts[#result.contacts + 1] = contact
        end

        remaining = remaining - #segment.path
        result.x, result.y = segment.x, segment.y

        if not segment.blocked then
            return result
        end

        local feature = ctx:cell(level_id,
            segment.blocked_x, segment.blocked_y)

        if not can_bounce(feature) then
            result.blocked = true
            result.blocked_x = segment.blocked_x
            result.blocked_y = segment.blocked_y
            return result
        end

        local step_x = segment.blocked_x - segment.x
        local step_y = segment.blocked_y - segment.y
        local reflect_x = step_x ~= 0
        local reflect_y = step_y ~= 0

        if reflect_x and reflect_y then
            local wall_x = not ctx:walkable(level_id,
                segment.x + step_x, segment.y)
            local wall_y = not ctx:walkable(level_id,
                segment.x, segment.y + step_y)

            if wall_x ~= wall_y then
                reflect_x, reflect_y = wall_x, wall_y
            end
        end

        if reflect_x then
            aim_x = -aim_x
        end
        if reflect_y then
            aim_y = -aim_y
        end

        x, y = segment.x, segment.y
        remaining = remaining - 2
        result.bounces = result.bounces + 1
    end

    return result
end

return trajectory
