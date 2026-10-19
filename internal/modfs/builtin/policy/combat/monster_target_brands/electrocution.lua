local damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")

local brand = {
    after_death = true,
}

-- Example: brand.apply(ctx, hit, brands) with defender with positive rElec -> no electrical burst
-- Roll the electrical burst after contact and resist it separately from base weapon damage.
function brand.apply(ctx, hit, brands)
    -- Source: attack.cc. Any positive rElec prevents the proc.
    local probe = damage.monster_elemental(ctx, hit.defender,
        1, resistances.ELECTRICITY)

    if probe < 1 or roll.melee(ctx, 4) ~= 0 then
        return
    end

    local raw = 8 + roll.melee(ctx, 13)
    local bonus = damage.monster_elemental(ctx, hit.defender,
        raw, resistances.ELECTRICITY)

    brands.damage(ctx, hit, bonus)
    ctx:emit("combat", "Lightning courses through the " ..
        hit.definition.name .. "!")
end

return brand
