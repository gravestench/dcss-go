-- Example: At D:3, an out-of-range row contributes no weight to the spawn draw.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local sentinels = require("constants.population_sentinels")

local pool = {}

-- Depth ranges gate a row before its weight enters the spawn pool.
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

-- Each branch owns its source rows. Extra population definitions can add rows
-- with a distinct ID, so a sparse mod does not need to copy a whole branch.
-- Definition IDs are sorted by catalog.all; file discovery cannot shift draws.
local function ordered_rows(branch_id, allowed, scenario_id)
    local source = {}

    for _, definition in ipairs(catalog.all(categories.POPULATIONS)) do
        if definition.branch_id == branch_id and
            (not definition.scenario_id or definition.scenario_id == scenario_id) then
            for _, row in ipairs(definition.rows) do
                if row.monster_id == sentinels.NO_MONSTER or
                    not allowed or allowed[row.monster_id] then
                    source[#source + 1] = {
                        id = row.monster_id,
                        row = row,
                    }
                end
            end
        end
    end

    return source
end

-- Keep duplicate source rows as separate weighted entries. Only one branch's
-- local depth enters the formula, regardless of its opaque level ID.
function pool.at_depth(branch_id, depth, allowed, scenario_id)
    local choices = {}
    local total = 0

    for _, entry in ipairs(ordered_rows(branch_id, allowed, scenario_id)) do
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

-- Spend one population-stream draw over the accumulated row weights.
function pool.pick(ctx, choices, total, stream)
    if total <= 0 then
        error("population pool has no supported entries")
    end

    local choice = ctx:random(stream or "population", total)

    for _, row in ipairs(choices) do
        if choice < row.weight then
            return row.id
        end

        choice = choice - row.weight
    end

    error("population pool failed to select")
end

return pool
