local net = require("policy.combat.net")
local hex_status = require("policy.combat.monster_hexes.status")

local dispersal = {}

-- Teleport candidates use Chebyshev distance to count diagonals as one step.
local function distance(a_x, a_y, b_x, b_y)
    return math.max(math.abs(a_x - b_x), math.abs(a_y - b_y))
end

-- Bound the random search and skip duplicate offsets before trying legal landing cells.
local function nearby_space(ctx, position, eligible)
    local visited = {}

    -- teleport.cc samples a 13-by-13 square at most 150 times.
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
                ctx:visible(position.level_id, position.x, position.y, 7, x, y) and
                (not eligible or eligible(x, y)) then
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

-- Example: with dimension-anchored monster,
-- dispersal.blink(ctx, attacker, monster, definition) -> false without moving it
-- Choose a safe relocation after a dispersal hit, leaving immobile targets at their current cell.
function dispersal.blink(ctx, attacker, monster, definition)
    if hex_status.anchored(ctx, monster) then
        return false
    end

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
