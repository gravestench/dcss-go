local roll = require("policy.combat.roll")
local player_health = require("policy.combat.player_health")
local necromancy = require("policy.combat.brand_necromancy")

local brand = {}

-- Example: brand.apply(ctx, hit) rolls Pain activation and bonus damage
-- independently, preserving both source skill draws.
function brand.apply(ctx, hit)
    local level = necromancy.monster_skill(ctx, hit.attacker)

    -- attack.cc: one_chance_in(skill + 1) prevents pain.
    if roll.melee(ctx, level + 1) == 0 then
        return
    end

    -- Source rolls the skill again for damage, independently of the
    -- skill roll that decided whether pain activates.
    local bonus = roll.melee(ctx,
        necromancy.monster_skill(ctx, hit.attacker) + 1)
    hit.health = player_health.damage(ctx, hit.defender, bonus,
        false, hit.attacker)

    if bonus > 0 then
        ctx:emit("combat", "You writhe in agony!")
    end
end

return brand
