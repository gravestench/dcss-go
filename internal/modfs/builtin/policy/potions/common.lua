local common = {}

function common.required(ctx, entity, name)
    local value = ctx:get(entity, name)

    if not value then
        error("potion target is missing " .. name)
    end

    return value
end

function common.average_three(ctx, bound)
    return math.floor((ctx:random("potion", bound) +
        ctx:random("potion", bound + 1) +
        ctx:random("potion", bound + 1)) / 3)
end

return common
