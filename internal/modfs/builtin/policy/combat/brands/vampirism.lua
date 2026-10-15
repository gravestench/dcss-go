local roll = require("policy.combat.roll")

local brand = {
    after_death = true,
}

function brand.apply(ctx, hit)
    if hit.damage_done < 1 then
        return
    end

    local health = ctx:get(hit.attacker, "core.health")

    if not health or health.current <= 0 or health.current >= health.max then
        return
    end

    -- attack.cc:1428-1469: a 60% proc on a damaging living target.
    if roll.melee(ctx, 5) < 2 then
        return
    end

    local healed = 1 + roll.melee(ctx, hit.damage_done)
    health.current = math.min(health.max, health.current + healed)
    ctx:set(hit.attacker, "core.health", health)
    ctx:emit("combat", "The " .. hit.attacker_name .. " draws strength from your wounds!")
end

return brand
