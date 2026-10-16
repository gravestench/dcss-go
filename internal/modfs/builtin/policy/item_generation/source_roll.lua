local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")

local roll = {}

function roll.chance(ctx, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if numerator >= denominator then
        return true
    end

    return ctx:random(streams.ITEM_GENERATION, denominator) < numerator
end

function roll.between(ctx, first, last)
    return first + ctx:random(streams.ITEM_GENERATION, last - first + 1)
end

function roll.average(ctx, bound, count)
    local sum = 0

    for _ = 1, count do
        sum = sum + ctx:random(streams.ITEM_GENERATION, bound)
    end

    return math.floor(sum / count)
end

function roll.one_of(ctx, ids)
    return catalog.get("items", ids[ctx:random(streams.ITEM_GENERATION, #ids) + 1])
end

function roll.weighted_id(ctx, rows)
    local total = 0

    for _, row in ipairs(rows) do
        total = total + row.weight
    end

    if total <= 0 then
        error("source item choice has no positive weight")
    end

    local draw = ctx:random(streams.ITEM_GENERATION, total)

    for _, row in ipairs(rows) do
        if draw < row.weight then
            return row.id or row.brand_id
        end

        draw = draw - row.weight
    end

    error("source item choice fell outside weighted table")
end

function roll.weighted(ctx, rows)
    return catalog.get("items", roll.weighted_id(ctx, rows))
end

return roll
