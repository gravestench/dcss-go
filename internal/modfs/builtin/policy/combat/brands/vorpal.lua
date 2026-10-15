local roll = require("policy.combat.roll")

return {
    apply = function(ctx, hit)
        if hit.damage_done == 0 then
            return
        end

        local bonus = 1 + math.floor(roll.melee(ctx, hit.damage_done) / 3)
        hit.health.current = math.max(0, hit.health.current - bonus)
    end,
}
