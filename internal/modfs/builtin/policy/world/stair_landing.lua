-- Theory of operation: stair links keep their authored coordinates, but
-- an actor may stand on the destination while the player is away. Search
-- the connected walkable area in a stable breadth-first order and place
-- the traveler nearby without moving the blocker or rewriting the link.
local landing = {}

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

-- The source stair wins when free. Only an occupied landing pays for the
-- search; visited cells and queue state belong to this one travel action.
function landing.find(ctx, level_id, start_x, start_y)
    local width, height = ctx:level_size(level_id)

    if not width or not height then
        error("stair destination level is missing")
    end

    local queue = {
        { x = start_x, y = start_y },
    }
    local visited = {
        [start_x .. ":" .. start_y] = true,
    }
    local cursor = 1

    while cursor <= #queue do
        local point = queue[cursor]

        cursor = cursor + 1

        if ctx:walkable(level_id, point.x, point.y) then
            if not ctx:actor_at(level_id, point.x, point.y) then
                return point.x, point.y
            end

            for _, direction in ipairs(directions) do
                local x = point.x + direction.x
                local y = point.y + direction.y
                local key = x .. ":" .. y

                if x >= 0 and x < width and y >= 0 and y < height and
                    not visited[key] and ctx:walkable(level_id, x, y) then
                    visited[key] = true
                    queue[#queue + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    error("stair destination has no free connected landing")
end

-- Population can put an authored monster on a region's preferred entry.
-- Reuse the same connected landing search before the portal publishes that
-- region, so the player never materializes on an occupied grid cell.
function landing.run(ctx, input)
    local x, y = landing.find(ctx, input.level_id, input.x, input.y)

    return {
        x = x,
        y = y,
    }
end

register.policy({
    id = "world.find_safe_landing",
    run = landing.run,
})

return landing
