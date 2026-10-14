local hit_points = {}

local function draw(ctx, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random("monster_hp", bound)
end

local function random_divide(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and draw(ctx, denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

function hit_points.roll(ctx, average)
    if average <= 0 then
        error("invalid monster average HP")
    end

    local variance = random_divide(ctx, average * 33, 100)
    local sum = draw(ctx, variance * 2)

    for _ = 1, 7 do
        sum = sum + draw(ctx, variance * 2 + 1)
    end

    local raw = average - variance + math.floor(sum / 8)
    local hp = random_divide(ctx, raw, 10)

    return math.min(10000, math.max(1, hp))
end

return hit_points
