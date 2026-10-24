-- Fog is one cloud-placement rule shared by scrolls and Xom. Callers own
-- their message and RNG stream; this owner chooses smoke, spreads outward,
-- and creates the same saved cloud entities for either source.
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local placement = require("policy.clouds.placement")

local fog = {}

local smoke_kinds = {
    cloud_ids.CLOUD_GREY_SMOKE,
    cloud_ids.CLOUD_BLUE_SMOKE,
    cloud_ids.CLOUD_BLACK_SMOKE,
    cloud_ids.CLOUD_PURPLE_SMOKE,
}

local directions = {
    {
        dx = -1,
        dy = -1,
    },

    {
        dx = 0,
        dy = -1,
    },

    {
        dx = 1,
        dy = -1,
    },

    {
        dx = -1,
        dy = 0,
    },

    {
        dx = 1,
        dy = 0,
    },

    {
        dx = -1,
        dy = 1,
    },

    {
        dx = 0,
        dy = 1,
    },

    {
        dx = 1,
        dy = 1,
    },
}

-- Coordinates are deduplicated before walking the next ring, so a blocked
-- corridor cannot create the same fog cloud through two parent cells.
local function key(x, y)
    return x .. ":" .. y
end

-- The source cloud helper rolls three duration dice for each placed cell.
-- Keeping each roll inside the placement loop preserves its RNG sequence.
local function duration(ctx, stream)
    local turns = 3

    for _ = 1, 3 do
        turns = turns + ctx:random(stream, 12)
    end

    return turns * 10
end

-- Choose one smoke colour and an eight-to-fifteen-cell target, then fill
-- reachable space from the player's square outward.
function fog.place(ctx, player, stream)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        error("fog requires player position")
    end

    local kind = smoke_kinds[ctx:random(stream, #smoke_kinds) + 1]
    local count = 8 + ctx:random(stream, 8)
    local frontier = {
        {
            x = origin.x,
            y = origin.y,
        },
    }
    local visited = { [key(origin.x, origin.y)] = true }
    local placed = 0

    while #frontier > 0 and placed < count do
        local next_ring = {}

        for _, cell in ipairs(frontier) do
            if placed < count and
                placement.place(ctx, kind, player, origin.level_id,
                    cell.x, cell.y, duration(ctx, stream)) then
                placed = placed + 1
            end

            for _, direction in ipairs(directions) do
                local x = cell.x + direction.dx
                local y = cell.y + direction.dy
                local id = key(x, y)

                if not visited[id] and
                    ctx:walkable(origin.level_id, x, y) then
                    visited[id] = true
                    next_ring[#next_ring + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end

        frontier = next_ring
    end

    return placed
end

return fog
