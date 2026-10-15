local fighter = require("policy.combat.fighter")
local roll = require("policy.combat.roll")

local brand = {}

local function skill(ctx)
    -- Source: attack.cc:552-568 calls skill_rdiv independently for the
    -- activation and damage rolls.
    return roll.random_divide(ctx,
        fighter.skill(ctx, "SK_NECROMANCY", 256), 256)
end

function brand.apply(ctx, hit, brands)
    local level = skill(ctx)

    if roll.melee(ctx, level + 1) == 0 then
        return
    end

    local raw = roll.melee(ctx, skill(ctx) + 1)
    local bonus = brands.negative(ctx, hit, raw)

    if bonus <= 0 then
        return
    end

    brands.damage(ctx, hit, bonus)
    ctx:emit("combat", "The " .. hit.definition.name .. " writhes in agony!")
end

return brand
