local accuracy = require("constants.beam_accuracy")
local roll = require("policy.combat.roll")

local calculators = {}

-- A catalogued AUTOMATIC_HIT sentinel bypasses the ordinary power-scaled to-hit formula.
local function calculate_hit_rule(profile, power)
    local rule = profile.monster_tohit

    if not rule then
        return 0
    end

    if rule.kind ~= "tohit" then
        error("unsupported monster beam to-hit calculator " ..
            tostring(rule.kind))
    end

    local args = rule.args

    if args[1] == "AUTOMATIC_HIT" then
        return accuracy.AUTOMATIC_HIT
    end

    return args[1] + math.floor(power * (args[2] or 0) / (args[3] or 1))
end

-- Enchantments contact automatically; damage beams use their catalog hit expression.
function calculators.to_hit(profile, power)
    if profile.is_enchantment then
        return accuracy.AUTOMATIC_HIT
    end

    return calculate_hit_rule(profile, power)
end

-- Hex power follows the profile's enchantment scale rather than damage dice.
function calculators.enchantment_power(profile, power)
    if not profile.is_enchantment then
        error("enchantment power requested for a damage beam")
    end

    if not profile.monster_tohit then
        return power
    end

    return calculate_hit_rule(profile, power)
end

-- Convert catalog damage formulas to dice before either contact or explosion rolls them.
function calculators.damage_dice(ctx, profile, power)
    local rule = profile.monster_damage

    if not rule then
        return {
            count = 0,
            sides = 0,
        }
    end

    local args = rule.args
    local count = args[1]
    local total = args[2] + math.floor(power * args[3] / args[4])

    if rule.kind == "dicedef" then
        return {
            count = count,
            sides = total,
        }
    end

    if rule.kind == "calcdice" then
        if count <= 1 then
            return {
                count = 1,
                sides = total,
            }
        end

        if total <= count then
            return {
                count = total,
                sides = 1,
            }
        end

        return {
            count = count,
            sides = roll.random_divide(ctx, total, count, "monster_spell"),
        }
    end

    error("unsupported monster beam damage calculator " ..
        tostring(rule.kind))
end

-- Example: calculators.roll_damage(ctx, dice) with dice.count = 0 -> 0 damage without RNG
-- The already converted dice roll on the monster spell stream at contact.
function calculators.roll_damage(ctx, dice)
    if dice.count <= 0 or dice.sides <= 0 then
        return 0
    end

    local total = dice.count

    for _ = 1, dice.count do
        total = total + roll.spell(ctx, dice.sides)
    end

    return total
end

return calculators
