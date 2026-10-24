local attacks = require("constants.auxiliary_attacks")
local auxiliary = require("policy.combat.auxiliary")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local roll = require("policy.combat.roll")
local lowered_will = require("policy.magic.effects.statuses.lowered_will")
local willpower = require("constants.willpower")

local touch = {
    id = attacks.TOUCH.id,
    order = attacks.TOUCH.order,
    chance = 40,
    mutation_ids = { mutations.MUT_DEMONIC_TOUCH },
    scale_with_level = false,
}

-- Demonic Touch reads effective rank because forms can suppress its benefit.
local function level(ctx)
    return levels.effective(ctx, ctx:player(), mutations.MUT_DEMONIC_TOUCH)
end

-- The touch occupies the offhand slot and requires active mutation rank.
function touch.available(ctx, input)
    return input.offhand and level(ctx) > 0
end

-- Example: touch.describe(ctx) with Touch mutation level zero -> base damage 6
-- Source: melee-attack.cc:AuxTouch.
function touch.describe(ctx)
    return {
        name = "touch",
        verb = "touch",
        base = 6 + roll.melee(ctx, level(ctx) * 4 + 1),
    }
end

-- Only a damaging rank-three touch can lower a nonimmune monster's will.
function touch.on_hit(ctx, target, definition, result)
    if result.damage <= 0 or level(ctx) < 3 or
        (definition.willpower or 0) >= willpower.INVULNERABLE then
        return 0
    end

    -- Source: melee-attack.cc:player_aux_apply, random_range(4, 8).
    lowered_will.apply(ctx, target, (4 + roll.melee(ctx, 5)) * 10)
    ctx:emit("combat", "You sap the " .. definition.name .. "'s willpower!")

    return 0
end

auxiliary.register(touch)

return touch
