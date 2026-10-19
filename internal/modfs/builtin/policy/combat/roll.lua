local roll = {}

-- Bounds of zero or one consume no RNG, preserving stream position for impossible variance.
function roll.draw(ctx, stream, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random(stream, bound)
end

-- Combat formulas share one named melee stream for replayable draw order.
function roll.melee(ctx, bound)
    return roll.draw(ctx, "melee", bound)
end

-- Monster spell rolls remain isolated from melee draws for deterministic combat.
function roll.spell(ctx, bound)
    return roll.draw(ctx, "monster_spell", bound)
end

-- Use a wider second bound to match source integer averaging without bias.
function roll.average_two(ctx, stream, bound)
    local first = roll.draw(ctx, stream, bound)
    local second = roll.draw(ctx, stream, bound + 1)

    return math.floor((first + second) / 2)
end

-- The two widened follow-up draws preserve source three-roll integer averaging.
function roll.average_three(ctx, stream, bound)
    local first = roll.draw(ctx, stream, bound)
    local second = roll.draw(ctx, stream, bound + 1)
    local third = roll.draw(ctx, stream, bound + 1)

    return math.floor((first + second + third) / 3)
end

-- Remainder draw stochastically rounds integer ratios instead of always flooring.
function roll.random_divide(ctx, numerator, denominator, stream)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and
        roll.draw(ctx, stream or "melee", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Example: roll.armour(ctx, 0) with zero RNG draws -> 0 armour saved
-- Preserve the odd-AC rounding draw even when no guaranteed reduction applies.
function roll.armour(ctx, ac)
    local saved = roll.melee(ctx, ac + 1)

    -- actor::apply_ac draws div_rand_round(AC, 2) even without GDR.
    if ac % 2 ~= 0 then
        roll.melee(ctx, 2)
    end

    return saved
end

-- Guaranteed damage reduction floors armour at capped AC/2 after the random AC roll.
function roll.gdr_armour(ctx, defense, potential)
    local saved = roll.melee(ctx, defense.ac + 1)
    local half = math.floor(defense.ac / 2)

    if defense.ac % 2 ~= 0 and roll.melee(ctx, 2) == 0 then
        half = half + 1
    end

    return math.max(saved, math.min(math.floor(defense.gdr * potential / 100), half))
end

return roll
