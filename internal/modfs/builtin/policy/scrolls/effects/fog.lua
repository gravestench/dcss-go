-- Source: item-use.cc:SCR_FOG calls big_cloud with power 50, size 8-15.
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")
local zap_ids = require("policy.magic.effects.zaps.ids")

local effect = {}

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

local function key(x, y)
    return x .. ":" .. y
end

local function duration(ctx)
    local turns = 3

    for _ = 1, 3 do
        turns = turns + ctx:random("spell", 12)
    end

    return turns * 10
end

function effect.prepare()
    return nil
end

function effect.apply(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local kind = smoke_kinds[ctx:random("spell", #smoke_kinds) + 1]
    local count = 8 + ctx:random("spell", 8)
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
                cloud.place(ctx, kind, player, origin.level_id,
                    cell.x, cell.y, duration(ctx)) then
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

    ctx:emit("read", "The scroll dissolves into smoke.")
end

scrolls.register(item_ids.SCR_FOG, effect)

return effect
