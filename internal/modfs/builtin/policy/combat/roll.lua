local roll = {}

function roll.draw(ctx, stream, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random(stream, bound)
end

function roll.melee(ctx, bound)
    return roll.draw(ctx, "melee", bound)
end

function roll.spell(ctx, bound)
    return roll.draw(ctx, "monster_spell", bound)
end

function roll.average_two(ctx, stream, bound)
    local first = roll.draw(ctx, stream, bound)
    local second = roll.draw(ctx, stream, bound + 1)

    return math.floor((first + second) / 2)
end

function roll.average_three(ctx, stream, bound)
    local first = roll.draw(ctx, stream, bound)
    local second = roll.draw(ctx, stream, bound + 1)
    local third = roll.draw(ctx, stream, bound + 1)

    return math.floor((first + second + third) / 3)
end

function roll.random_divide(ctx, numerator, denominator, stream)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and
        roll.draw(ctx, stream or "melee", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

function roll.armour(ctx, ac)
    local saved = roll.melee(ctx, ac + 1)

    -- actor::apply_ac draws div_rand_round(AC, 2) even without GDR.
    if ac % 2 ~= 0 then
        roll.melee(ctx, 2)
    end

    return saved
end

function roll.gdr_armour(ctx, defense, potential)
    local saved = roll.melee(ctx, defense.ac + 1)
    local half = math.floor(defense.ac / 2)

    if defense.ac % 2 ~= 0 and roll.melee(ctx, 2) == 0 then
        half = half + 1
    end

    return math.max(saved, math.min(math.floor(defense.gdr * potential / 100), half))
end

return roll
