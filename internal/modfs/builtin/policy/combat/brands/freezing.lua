local roll = require("policy.combat.roll")
local player_health = require("policy.combat.player_health")

local brand = {
    after_death = true,
}

function brand.apply(ctx, hit)
    if hit.damage_done == 0 then
        return
    end

    local bonus = 1 + math.floor(roll.melee(ctx, hit.damage_done) / 2)
    hit.health = player_health.damage(ctx, hit.defender, bonus,
        false, hit.attacker)
    ctx:emit("combat", "The " .. hit.attacker_name .. " freezes you.")
end

return brand
