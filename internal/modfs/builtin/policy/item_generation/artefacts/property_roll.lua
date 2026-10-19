local pool = require("policy.item_generation.artefacts.property_pool")
local rules = require("policy.item_generation.artefacts.property_rules")
local source = require("policy.item_generation.source_roll")
local values = require("policy.item_generation.artefacts.property_values")
local properties = require("ids.artefact_properties")

local roll = {}

-- Independent percentage draws shape property quality before budget allocation.
local function binomial(ctx, trials, probability)
    local hits = 0

    for _ = 1, trials do
        if source.chance(ctx, probability, 100) then
            hits = hits + 1
        end
    end

    return hits
end

-- Stochastic rounding preserves fractional bad-property budget odds.
local function rounded_division(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if source.chance(ctx, remainder, denominator) then
        quotient = quotient + 1
    end

    return quotient
end

-- Source property quality yields separate good and bad budgets; overflow enhances selected good properties.
local function budgets(ctx)
    -- Source: crawl-ref/source/artefact.cc.
    local quality = math.max(1, binomial(ctx, 7, 30))
    local bad = math.min(binomial(ctx,
        1 + rounded_division(ctx, quality, 5), 30), 2)
    local good = quality + bad
    local limit = 4

    if source.chance(ctx, 1, 20) then
        limit = limit + 1
    end

    if source.chance(ctx, 1, 40) then
        limit = limit + 1
    end

    local enhance = 0

    if good + bad > limit then
        enhance = good + bad - limit
        good = limit - bad
    end

    return good, bad, enhance
end

-- Draw by current weights after incompatible or spent properties leave the pool.
local function select_property(ctx, candidates)
    local rows = {}

    for _, entry in ipairs(candidates) do
        rows[#rows + 1] = {
            id = entry.id,
            weight = entry.weight,
        }
    end

    local id = source.weighted_id(ctx, rows)

    for index, entry in ipairs(candidates) do
        if entry.id == id then
            return index, entry
        end
    end

    error("selected artefact property has no declaration " .. id)
end

-- Enhancement can spend overflow budget on a selected good property without adding another slot.
local function add_good(ctx, entry, properties_map, good, enhance)
    local current = properties_map[entry.id] or 0

    if (entry.id == properties.STRENGTH or
        entry.id == properties.INTELLIGENCE or
        entry.id == properties.DEXTERITY) and current == 0 then
        current = 1
    end

    local denominator = 1
    local maximum = entry.max or 0
    local increase = entry.increase or 0

    while current <= maximum and
        (enhance > 0 or
            (good > 0 and source.chance(ctx, 1, denominator))) do
        current = current + values.good(ctx, entry.good)

        if enhance > 0 and denominator > 1 then
            enhance = enhance - 1
        else
            good = good - 1
        end

        denominator = denominator + increase
    end

    properties_map[entry.id] = current

    return good, enhance
end

-- Example: a weapon's current brand filters incompatible property candidates before either budget is spent.
-- Spend good and bad budgets from a shrinking candidate pool so a property is selected at most once.
function roll.properties(ctx, definition, brand)
    local good, bad, enhance = budgets(ctx)
    local candidates = {}
    local result = {}

    for index, entry in ipairs(pool) do
        candidates[index] = entry
    end

    local attempts = 0

    while good > 0 or bad > 0 do
        attempts = attempts + 1

        if attempts > 10000 or #candidates == 0 then
            error("artefact property source pool cannot spend its budgets")
        end

        local index, entry = select_property(ctx, candidates)

        if rules.compatible(entry.id, definition, result, brand) then
            local can_good = good > 0 and entry.good ~= nil
            local can_bad = bad > 0 and entry.bad ~= nil
            local choose_good = can_good and
                (not can_bad or source.chance(ctx, 1, 2))

            if choose_good then
                good, enhance = add_good(ctx, entry, result, good, enhance)
                table.remove(candidates, index)
            elseif can_bad then
                result[entry.id] = values.bad(ctx, entry.bad)
                bad = bad - 1
                table.remove(candidates, index)
            end
        end
    end

    return result
end

return roll
