local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local pool = {}

local function weight_at_depth(row, depth)
    if depth < row.min_depth or depth > row.max_depth then
        return 0
    end

    local rarity = row.rarity * 2520
    local length = row.max_depth - row.min_depth

    if row.curve == curves.FLAT then
        return rarity
    end

    if row.curve == curves.SEMI then
        length = length == 0 and 2 or length * 2

        return math.floor(rarity *
            (length - math.abs(row.min_depth + row.max_depth - 2 * depth)) / length)
    end

    if row.curve == curves.PEAK then
        length = length + 2

        return math.floor(rarity *
            (length - math.abs(row.min_depth + row.max_depth - 2 * depth)) / length)
    end

    if row.curve == curves.RISE then
        return math.floor(rarity * (depth - row.min_depth + 1) / (length + 1))
    end

    if row.curve == curves.FALL then
        return math.floor(rarity * (row.max_depth - depth + 1) / (length + 1))
    end

    error("unsupported population curve " .. tostring(row.curve))
end

local function ordered_rows(allowed, scenario_id)
    local source = {}
    local added = {}

    for _, definition in ipairs(catalog.all(categories.MONSTERS)) do
        if not allowed or allowed[definition.id] then
            for _, row in ipairs(definition.population or {}) do
                local entry = {
                    id = definition.id,
                    row = row,
                }

                if row.source_order then
                    source[#source + 1] = entry
                elseif row.scenario_id == scenario_id then
                    added[#added + 1] = entry
                end
            end
        end
    end

    table.sort(source, function(a, b)
        return a.row.source_order < b.row.source_order
    end)

    for _, entry in ipairs(added) do
        source[#source + 1] = entry
    end

    return source
end

function pool.at_depth(depth, allowed, scenario_id)
    local choices = {}
    local total = 0

    -- Source order is explicit because monster files load in ID order.
    -- Duplicate monster IDs remain separate picker rows.
    for _, entry in ipairs(ordered_rows(allowed, scenario_id)) do
        local weight = weight_at_depth(entry.row, depth)

        if weight > 0 then
            choices[#choices + 1] = {
                id = entry.id,
                weight = weight,
            }
            total = total + weight
        end
    end

    return choices, total
end

function pool.pick(ctx, choices, total, stream)
    if total <= 0 then
        error("Dungeon has no supported population")
    end

    local choice = ctx:random(stream or "population", total)

    for _, row in ipairs(choices) do
        if choice < row.weight then
            return row.id
        end

        choice = choice - row.weight
    end

    error("Dungeon population pool failed to select")
end

return pool
