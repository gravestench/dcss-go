local component = require("constants.component")
local net = require("policy.combat.net")

local relocation = {}

local function adjacent(position, level_id, x, y)
    return position and position.level_id == level_id and
        math.max(math.abs(position.x - x), math.abs(position.y - y)) <= 1
end

local function release_player_links(ctx, monster, level_id, x, y)
    local player = ctx:player()
    local player_position = ctx:get(player, component.POSITION)

    if adjacent(player_position, level_id, x, y) then
        return
    end

    local grip = ctx:get(player, component.CONSTRICTION)

    if grip and grip.by == monster then
        ctx:remove(player, component.CONSTRICTION)
    end

    if ctx:has(monster, component.PLAYER_CONSTRICTION) then
        ctx:remove(monster, component.PLAYER_CONSTRICTION)
    end

    if ctx:has(monster, component.WATER_HOLD) then
        ctx:remove(monster, component.WATER_HOLD)
    end
end

local function release_band_links(ctx, monster, level_id, origin_level)
    if level_id == origin_level then
        return
    end

    if ctx:has(monster, component.FOLLOWER) then
        ctx:remove(monster, component.FOLLOWER)
    end

    for _, entity in ipairs(ctx:query({ component.FOLLOWER })) do
        local follower = ctx:get(entity, component.FOLLOWER)

        if follower.leader == monster then
            ctx:remove(entity, component.FOLLOWER)
        end
    end
end

function relocation.move(ctx, monster, level_id, x, y)
    local origin = ctx:get(monster, component.POSITION)

    if not origin then
        error("relocated monster has no position")
    end

    net.release(ctx, monster)
    release_player_links(ctx, monster, level_id, x, y)
    release_band_links(ctx, monster, level_id, origin.level_id)
    ctx:move_actor(monster, level_id, x, y)
end

return relocation
