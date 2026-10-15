local confusion = require("policy.magic.effects.statuses.confusing_touch")

local brand = {}

function brand.apply(ctx, hit)
    -- Source: attack.cc:1484-1537. Chaos can select confusion even with
    -- no base damage; the enchantment still checks the monster's will.
    confusion.apply(ctx, hit.defender, hit.definition,
        math.max(1, hit.damage_done))
end

return brand
