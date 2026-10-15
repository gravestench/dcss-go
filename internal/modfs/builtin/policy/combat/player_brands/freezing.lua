local damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")

local brand = {
    after_death = true,
    requires_damage = true,
}

function brand.apply(ctx, hit, brands)
    -- Source: attack.cc:1387-1391,1618.
    local raw = 1 + math.floor(roll.melee(ctx, hit.damage_done) / 2)
    local bonus = damage.monster_elemental(ctx, hit.defender,
        raw, resistances.COLD)

    if bonus <= 0 then
        return
    end

    brands.damage(ctx, hit, bonus)
    ctx:emit("combat", "Your weapon freezes the " .. hit.definition.name .. ".")
end

return brand
