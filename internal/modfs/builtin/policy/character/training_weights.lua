local weights = {}

local function remainder_before(left, right)
    if left.value == right.value then
        return left.index < right.index
    end

    return left.value < right.value
end

function weights.setting(training, id)
    for _, setting in ipairs(training.settings) do
        if setting.id == id then
            return setting
        end
    end

    return nil
end

local function count(queue, id)
    local result = 0

    for _, candidate in ipairs(queue) do
        if candidate == id then
            result = result + 1
        end
    end

    return result
end

function weights.scaled(skills, training)
    local values = {}
    local had_practice = false

    for index, skill in ipairs(skills) do
        local setting = weights.setting(training, skill.id)
        local weight = 0

        if setting and setting.enabled and skill.level < 27 then
            if training.manual then
                weight = setting.focused and 2 or 1
            else
                weight = math.max(
                    count(training.recent_practice, skill.id),
                    count(training.recent_all, skill.id))

                if setting.focused then
                    weight = weight * 2
                end

                had_practice = had_practice or weight > 0
            end
        end

        values[index] = weight
    end

    if not training.manual and not had_practice then
        for index, skill in ipairs(skills) do
            local setting = weights.setting(training, skill.id)

            if setting and setting.enabled and skill.level < 27 then
                values[index] = setting.focused and 2 or 1
            end
        end
    end

    if not training.manual then
        for index, skill in ipairs(skills) do
            local setting = weights.setting(training, skill.id)

            if setting and setting.enabled and setting.focused and skill.level < 27 and
                values[index] < 20 then
                values[index] = values[index] + 5 * (5 - math.floor(values[index] / 4))
            end
        end
    end

    local total = 0

    for _, weight in ipairs(values) do
        total = total + weight
    end

    if total == 0 then
        return values
    end

    local remainders = {}
    local scaled_total = 0

    for index, weight in ipairs(values) do
        if weight > 0 then
            local product = weight * 100
            values[index] = math.floor(product / total)
            scaled_total = scaled_total + values[index]
            local rest = product % total

            if rest > 0 then
                remainders[#remainders + 1] = { index = index, value = rest }
            end
        end
    end

    if not training.manual then
        table.sort(remainders, remainder_before)

        for _, rest in ipairs(remainders) do
            if scaled_total == 100 then
                break
            end

            values[rest.index] = values[rest.index] + 1
            scaled_total = scaled_total + 1
        end
    end

    return values
end

function weights.choose(ctx, values)
    local total = 0

    for _, weight in ipairs(values) do
        total = total + weight
    end

    if total == 0 then
        return nil
    end

    local choice = ctx:random("skill", total)

    for index, weight in ipairs(values) do
        if choice < weight then
            return index
        end

        choice = choice - weight
    end

    error("skill weight selection escaped total " .. total)
end

return weights
