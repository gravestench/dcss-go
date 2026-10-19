local fighter = require("policy.combat.fighter")
local roll = require("policy.combat.roll")
local component = require("constants.component")
local necromancy = require("policy.combat.brand_necromancy")

local brand = {}

-- Roll Necromancy skill independently for Pain activation and bonus damage.
local function skill(ctx, attacker)
    -- Source: attack.cc calls skill_rdiv independently for the
    -- activation and damage rolls.
    if ctx:has(attacker, component.PLAYER) then
        return roll.random_divide(ctx,
            fighter.skill(ctx, "SK_NECROMANCY", 256), 256)
    end

    return necromancy.monster_skill(ctx, attacker)
end

-- Example: brand.apply(ctx, hit, brands) with Necromancy skill zero -> no Pain bonus damage
-- Use independent Necromancy rolls for activation and damage before negative-energy resistance.
function brand.apply(ctx, hit, brands)
    local level = skill(ctx, hit.attacker)

    if roll.melee(ctx, level + 1) == 0 then
        return
    end

    local raw = roll.melee(ctx, skill(ctx, hit.attacker) + 1)
    local bonus = brands.negative(ctx, hit, raw)

    if bonus <= 0 then
        return
    end

    brands.damage(ctx, hit, bonus)
    ctx:emit("combat", "The " .. hit.definition.name .. " writhes in agony!")
end

return brand
