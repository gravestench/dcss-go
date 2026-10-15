local net = require("policy.combat.net")

local dispersal = {}

local function distance(a_x, a_y, b_x, b_y)
    return math.max(math.abs(a_x - b_x), math.abs(a_y - b_y))
end

local function nearby_space(ctx, position)
    local visited = {}

    -- teleport.cc:452-489 samples a 13-by-13 square at most 150 times.
    for _ = 1, 150 do
        local offset_x = ctx:random("melee", 13) - 6
        local offset_y = ctx:random("melee", 13) - 6
        local key = (offset_x + 6) * 13 + offset_y + 6

        if not visited[key] then
            visited[key] = true

            local x = position.x + offset_x
            local y = position.y + offset_y

            if distance(position.x, position.y, x, y) > 1 and
                ctx:walkable(position.level_id, x, y) and
                not ctx:actor_at(position.level_id, x, y) and
                ctx:visible(position.level_id, position.x, position.y, 7, x, y) then
                return {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return nil
end

dispersal.nearby_space = nearby_space

function dispersal.blink(ctx, attacker, monster, definition)
    local origin = ctx:get(monster, "core.position")
    local first = nearby_space(ctx, origin)
    local second = nearby_space(ctx, origin)

    if not first or not second then
        return false
    end

    local from = ctx:get(attacker, "core.position")
    local first_distance = distance(from.x, from.y, first.x, first.y)
    local second_distance = distance(from.x, from.y, second.x, second.y)
    local destination = second_distance > first_distance and second or first

    net.release(ctx, monster)
    ctx:move_actor(monster, origin.level_id, destination.x, destination.y)
    ctx:emit("combat", "The " .. definition.name .. " blinks away!")

    return true
end

return dispersal
