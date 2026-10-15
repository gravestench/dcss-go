local rows = require("data.dungeon_population").rows
local catalog = require("policy.catalog")

local pool = {}

local function weight_at_depth(row, depth)
    if depth < row.min_depth or depth > row.max_depth then
        return 0
    end

    local rarity = row.rarity * 2520
    local length = row.max_depth - row.min_depth

    if row.curve == "FLAT" then
        return rarity
    end

    if row.curve == "SEMI" then
        length = length == 0 and 2 or length * 2

        return math.floor(rarity *
            (length - math.abs(row.min_depth + row.max_depth - 2 * depth)) / length)
    end

    if row.curve == "PEAK" then
        length = length + 2

        return math.floor(rarity *
            (length - math.abs(row.min_depth + row.max_depth - 2 * depth)) / length)
    end

    if row.curve == "RISE" then
        return math.floor(rarity * (depth - row.min_depth + 1) / (length + 1))
    end

    if row.curve == "FALL" then
        return math.floor(rarity * (row.max_depth - depth + 1) / (length + 1))
    end

    error("unsupported population curve " .. tostring(row.curve))
end

function pool.at_depth(depth, allowed, scenario_id)
    local choices = {}
    local total = 0

    -- Duplicate IDs remain separate rows, preserving source picker order.
    for _, row in ipairs(rows) do
        if allowed[row.monster_id] then
            local weight = weight_at_depth(row, depth)

            if weight > 0 then
                choices[#choices + 1] = {
                    id = row.monster_id,
                    weight = weight,
                }
                total = total + weight
            end
        end
    end

    -- Mod rows follow source rows, preserving the source picker order.
    for _, definition in ipairs(catalog.all("monsters")) do
        if allowed[definition.id] then
            for _, row in ipairs(definition.population or {}) do
                if row.scenario_id == scenario_id then
                    local weight = weight_at_depth(row, depth)

                    if weight > 0 then
                        choices[#choices + 1] = {
                            id = definition.id,
                            weight = weight,
                        }
                        total = total + weight
                    end
                end
            end
        end
    end

    return choices, total
end

function pool.pick(ctx, choices, total)
    if total <= 0 then
        error("Dungeon has no supported population")
    end

    local choice = ctx:random("population", total)

    for _, row in ipairs(choices) do
        if choice < row.weight then
            return row.id
        end

        choice = choice - row.weight
    end

    error("Dungeon population pool failed to select")
end

return pool
