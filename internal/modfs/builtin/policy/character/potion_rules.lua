-- Example: A Mummy fails can_drink before a healing potion can apply its HP factor.
-- Source: player.cc:can_drink and scale_potion_healing.
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local restrictions = require("constants.safety_restrictions")
local safety = require("policy.character.damage_safety")

local potion_rules = {}

-- Check Drink Safety before species and form restrictions can admit a potion.
function potion_rules.can_drink(ctx, player)
    if safety.active(ctx, player, restrictions.POTIONS) then
        return false
    end

    return effects.sum(ctx, player,
        capabilities.POTION_FORBIDDEN) == 0
end

-- The source expresses the healing multiplier in halves.
function potion_rules.healing_factor(ctx, player)
    local penalty = effects.sum(ctx, player,
        capabilities.POTION_HEALING_PENALTY)

    return math.max(0, 2 - penalty)
end

-- Use the effective healing factor so zero-healing forms reject restorative potions.
function potion_rules.can_heal(ctx, player)
    return potion_rules.healing_factor(ctx, player) > 0
end

-- Use the half-step healing factor only after drinkability and healing rules choose an eligible potion.
function potion_rules.scale_healing(ctx, player, amount)
    local numerator = amount * potion_rules.healing_factor(ctx, player)
    local whole = math.floor(numerator / 2)

    if numerator % 2 > 0 and ctx:random("potion", 2) == 0 then
        return whole + 1
    end

    return whole
end

return potion_rules
