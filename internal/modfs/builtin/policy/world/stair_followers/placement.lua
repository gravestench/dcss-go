-- Placement searches the connected walkable area around the player's
-- arrival stair. Occupied cells may be crossed but cannot hold a follower.
local habitat = require("policy.combat.monster_habitat")

local placement = {}

-- A fixed eight-neighbor order makes the same seed choose the same cells
-- regardless of Lua file discovery order or Akara query order.
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

-- Export this order for source-floor wave selection as well. Both ends
-- should use the same deterministic concept of neighboring cells.
placement.directions = directions

-- Walk the destination's connected open area in stable coordinate order.
-- An occupied cell is still traversable for search, so a crowd around
-- the stair does not hide an open square farther away.
function placement.find(ctx, entity, level_id, x, y)
    local width, height = ctx:level_size(level_id)
    local queue = {
        {
            x = x,
            y = y,
        },
    }
    local seen = {
        [x .. ":" .. y] = true,
    }
    local cursor = 1

    while cursor <= #queue do
        local point = queue[cursor]

        cursor = cursor + 1

        if ctx:walkable(level_id, point.x, point.y) then
            if not ctx:actor_at(level_id, point.x, point.y) and
                habitat.at(ctx, entity, level_id, point.x, point.y) then
                return point.x, point.y
            end

            for _, direction in ipairs(directions) do
                local next_x = point.x + direction.x
                local next_y = point.y + direction.y
                local key = next_x .. ":" .. next_y

                if next_x >= 0 and next_y >= 0 and
                    next_x < width and next_y < height and
                    not seen[key] and
                    ctx:walkable(level_id, next_x, next_y) then
                    seen[key] = true
                    queue[#queue + 1] = {
                        x = next_x,
                        y = next_y,
                    }
                end
            end
        end
    end

    return nil
end

return placement
