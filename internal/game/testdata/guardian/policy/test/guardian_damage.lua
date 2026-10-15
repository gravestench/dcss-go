local causes = require("constants.damage_causes")
local component = require("constants.component")
local player_health = require("policy.combat.player_health")

local policy = {}

function policy.run(ctx)
    local player = ctx:player()
    local health = ctx:get(player, component.HEALTH)
    local damage = health.max - 1

    player_health.damage(ctx, player, damage, false, nil, causes.HIT)

    return {
        damage = damage,
    }
end

register.policy({
    id = "test.guardian_damage",
    run = policy.run,
})

return policy
