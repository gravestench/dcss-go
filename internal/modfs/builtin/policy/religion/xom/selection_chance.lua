-- Xom's action selector uses the source x_chance_in_y rule. Impossible and
-- certain outcomes do not spend an RNG draw, so later choices keep their
-- intended seeded order.
local chance = {}

-- A positive numerator below the denominator draws exactly once.
function chance.in_y(ctx, stream, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if numerator >= denominator then
        return true
    end

    return ctx:random(stream, denominator) < numerator
end

return chance
