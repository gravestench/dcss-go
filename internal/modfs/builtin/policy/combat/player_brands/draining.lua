local drain = require("policy.combat.monster_drain")
local roll = require("policy.combat.roll")

local brand = {}

-- Example: brand.apply(ctx, hit, brands) with resistant defender -> no negative-energy bonus
-- Drain living monsters through shared negative-energy resistance and preserve player kill credit.
function brand.apply(ctx, hit, brands)
    -- Source: melee-attack.cc and attack.cc. A monster
    -- avoids half the draining attempts before resistance is checked.
    if roll.melee(ctx, 2) == 0 or
        drain.resistance(ctx, hit.defender, hit.definition) >= 3 then
        return
    end

    local raw = math.floor((1 + roll.melee(ctx, hit.damage_done)) / 2)
    local bonus = brands.negative(ctx, hit, raw)

    drain.apply(ctx, hit.defender, hit.definition, hit.attacker, "melee")
    hit.health = ctx:get(hit.defender, "core.health")

    if hit.health.current > 0 and bonus > 0 then
        brands.damage(ctx, hit, bonus)
    end
end

return brand
