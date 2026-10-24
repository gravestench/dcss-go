-- The source uses one connected actor wave for both stairs and within-level
-- transporter travel. Search actor positions, not Akara query order, so a
-- content registration or entity creation change cannot reshuffle followers.
local component = require("constants.component")
local eligibility = require("policy.world.follower_eligibility")

local wave = {}
local directions = {}

for dy = -1, 1 do
    for dx = -1, 1 do
        if dx ~= 0 or dy ~= 0 then
            directions[#directions + 1] = {
                x = dx,
                y = dy,
            }
        end
    end
end

wave.directions = directions

-- An accepted actor expands the wave. The caller applies the transfer
-- limit: stairs count tagged actors, whereas a transporter counts only
-- actors that found a free destination cell.
function wave.select(ctx, player, origin, mode)
    local width, height = ctx:level_size(origin.level_id)
    local maximum = eligibility.radius(ctx, origin, width, height,
        directions)
    local queue = {
        {
            x = origin.x,
            y = origin.y,
        },
    }
    local seen = {
        [origin.x .. ":" .. origin.y] = true,
    }
    local cursor = 1
    local selected = {}

    while cursor <= #queue do
        local point = queue[cursor]

        cursor = cursor + 1

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local key = x .. ":" .. y
            local distance = math.max(math.abs(x - origin.x),
                math.abs(y - origin.y))

            if x >= 0 and y >= 0 and x < width and y < height and
                distance <= maximum and not seen[key] then
                seen[key] = true

                local entity = ctx:actor_at(origin.level_id, x, y)

                if entity and entity ~= player and
                    ctx:has(entity, component.ACTOR) and
                    eligibility.can_follow(ctx, entity, origin, mode) then
                    selected[#selected + 1] = entity
                    queue[#queue + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    return selected
end

return wave
