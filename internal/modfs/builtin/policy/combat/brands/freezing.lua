local roll = require("policy.combat.roll")

return {
    after_death = true,

    apply = function(ctx, hit)
        if hit.damage_done == 0 then
            return
        end

        local bonus = 1 + math.floor(roll.melee(ctx, hit.damage_done) / 2)
        hit.health.current = math.max(0, hit.health.current - bonus)
        ctx:emit("combat", "The " .. hit.attacker_name .. " freezes you.")
    end,
}
