local damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")

local brand = {
    after_death = true,
    requires_damage = true,
}

-- Example: brand.apply(ctx, hit, brands) with cold-vulnerable defender -> extra cold damage and a freeze message
-- Freezing uses the dealt weapon damage for its extra cold roll, then applies monster cold resistance.
function brand.apply(ctx, hit, brands)
    -- Source: attack.cc,1618.
    local raw = 1 + math.floor(roll.melee(ctx, hit.damage_done) / 2)
    local bonus = damage.monster_elemental(ctx, hit.defender,
        raw, resistances.COLD)

    if bonus <= 0 then
        return
    end

    brands.damage(ctx, hit, bonus)
    ctx:emit("combat", brands.subject(ctx, hit) .. " freezes the " ..
        hit.definition.name .. ".")
end

return brand
