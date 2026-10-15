local habitat = require("policy.combat.monster_habitat")

local fear = {}

local function distance(x, y, player)
    return math.max(math.abs(x - player.x), math.abs(y - player.y))
end

-- The fear source is the player. Move to an open neighboring cell that
-- increases distance from the player; pick an equally good cell with AI RNG.
function fear.flee(ctx, monster, position, player)
    local current = distance(position.x, position.y, player)
    local best = current
    local choices = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy
                local next_distance = distance(x, y, player)

                if next_distance >= best and
                    habitat.at(ctx, monster, position.level_id, x, y) and
                    not ctx:actor_at(position.level_id, x, y) then
                    if next_distance > best then
                        best = next_distance
                        choices = {}
                    end

                    choices[#choices + 1] = {
                        kind = 1,
                        dx = dx,
                        dy = dy,
                    }
                end
            end
        end
    end

    if #choices == 0 then
        return { kind = 6 }
    end

    return choices[ctx:random("ai", #choices) + 1]
end

return fear
