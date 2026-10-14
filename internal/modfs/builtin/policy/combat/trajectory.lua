-- Trace a cell-centre projectile ray through the dense grid. This uses the
-- same tie-breaking geometry as Level.ClearProjectilePath. Contacts are
-- resolved in order by the attack policy: a miss keeps flying, while a hit
-- stops an ordinary missile. Shots continue past the cursor up to range.
local trajectory = {}

function trajectory.trace(ctx, level_id, from_x, from_y, to_x, to_y, range)
    local aim_x = to_x - from_x
    local aim_y = to_y - from_y

    if range then
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
                actors = actors,
                contacts = contacts,
            }
        end

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
        actors = actors,
        contacts = contacts,
    }
end

return trajectory
