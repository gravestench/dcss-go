local common = {}

-- Potion effects share a required-state check and a three-draw average helper.
function common.required(ctx, entity, name)
    local value = ctx:get(entity, name)

    if not value then
        error("potion target is missing " .. name)
    end

    return value
end

-- Average three potion-stream draws with source bounds to soften the healing roll distribution.
-- Example: a healing potion can average three potion-stream rolls rather than use one uniform draw.
function common.average_three(ctx, bound, stream)
    stream = stream or "potion"

    return math.floor((ctx:random(stream, bound) +
        ctx:random(stream, bound + 1) +
        ctx:random(stream, bound + 1)) / 3)
end

return common
