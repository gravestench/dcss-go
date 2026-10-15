local targets = require("policy.ai.targets")

local target = {}

function target.visible_hostile(ctx, player, reach, needs_path)
    local position = ctx:get(player, "core.position")

    for _, monster in ipairs(ctx:query({
        "core.actor",
        "core.position",
        "core.health",
    })) do
        if targets.enemy(ctx, player, monster) then
            local location = ctx:get(monster, "core.position")
            local health = ctx:get(monster, "core.health")
            local distance = math.max(
                math.abs(location.x - position.x),
                math.abs(location.y - position.y))

            if health.current > 0 and
                location.level_id == position.level_id and
                distance <= reach and
                ctx:visible(position.level_id, position.x, position.y,
                    7, location.x, location.y) and
                (not needs_path or ctx:projectile_clear(
                    position.level_id, position.x, position.y,
                    location.x, location.y)) then
                return true
            end
        end
    end

    return false
end

function target.at_aim(ctx, player, intent)
    local position = ctx:get(player, "core.position")
    local x = position.x + intent.dx
    local y = position.y + intent.dy
    local actor = ctx:actor_at(position.level_id, x, y)

    if actor == player then
        return nil, position.level_id, x, y
    end

    return actor, position.level_id, x, y
end

return target
