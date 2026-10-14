local spells = require("policy.combat.spells")

local freeze = {}

function freeze.can_cast(_, caster_pos, player_pos)
    return caster_pos.level_id == player_pos.level_id and
        math.abs(caster_pos.x - player_pos.x) <= 1 and
        math.abs(caster_pos.y - player_pos.y) <= 1 and
        (caster_pos.x ~= player_pos.x or caster_pos.y ~= player_pos.y)
end

function freeze.resolve(ctx, _, _, definition, player_health)
    local player = ctx:player()
    local damage = spells.freeze(ctx, definition.hd)
    player_health.current = math.max(0, player_health.current - damage)
    ctx:set(player, "core.health", player_health)
    ctx:emit("combat", "You are frozen.")
end

return freeze
