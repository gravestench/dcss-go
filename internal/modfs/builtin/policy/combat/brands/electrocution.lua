local roll = require("policy.combat.roll")

return {
    after_death = true,

    apply = function(ctx, hit)
        if roll.melee(ctx, 4) ~= 0 then
            return
        end

        local bonus = 8 + roll.melee(ctx, 13)
        hit.health.current = math.max(0, hit.health.current - bonus)

        if bonus >= 18 then
            ctx:emit("combat", "You are electrocuted!!")
        else
            ctx:emit("combat", "You are electrocuted!")
        end
    end,
}
