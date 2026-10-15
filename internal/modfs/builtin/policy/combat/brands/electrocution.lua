local roll = require("policy.combat.roll")
local player_health = require("policy.combat.player_health")

local brand = {
    after_death = true,
}

function brand.apply(ctx, hit)
    if roll.melee(ctx, 4) ~= 0 then
        return
    end

    local bonus = 8 + roll.melee(ctx, 13)
    hit.health = player_health.damage(ctx, hit.defender, bonus,
        false, hit.attacker)

    if bonus >= 18 then
        ctx:emit("combat", "You are electrocuted!!")
    else
        ctx:emit("combat", "You are electrocuted!")
    end
end

return brand
