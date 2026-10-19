local confusion = require("policy.magic.effects.statuses.confusing_touch")

local brand = {}

-- Example: brand.apply(ctx, hit) with susceptible defender -> attempts confusion after contact
-- A landed confusing hit checks the target's susceptibility before storing the debuff.
function brand.apply(ctx, hit)
    -- Source: attack.cc. Chaos can select confusion even with
    -- no base damage; the enchantment still checks the monster's will.
    confusion.apply(ctx, hit.defender, hit.definition,
        math.max(1, hit.damage_done))
end

return brand
