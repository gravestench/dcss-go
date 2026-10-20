-- One run chooses its Temple map, altar count, and god partition before
-- the first Dungeon floor. All later Temple work consumes this saved plan.
local gods = require("constants.gods")
local streams = require("constants.rng_streams")
local default_catalog = require("policy.generation.temple.catalog")

local plan = {}

local excluded = {
    [gods.NO_GOD] = true,
    [gods.LUGONU] = true,
    [gods.BEOGH] = true,
    [gods.JIYVA] = true,
    [gods.IGNIS] = true,
}

-- The current source god IDs are Lua constants. Sorting them removes Lua
-- table iteration order from the seeded shuffle and saved partition.
local function temple_gods()
    local result = {}

    for _, id in pairs(gods) do
        if not excluded[id] then
            result[#result + 1] = id
        end
    end

    table.sort(result)

    return result
end

-- Expose the effective source pool for Temple placement and tests without
-- declaring a second list of god IDs in either caller.
function plan.god_ids()
    return temple_gods()
end

-- Source ordinary counts have thick tails: the lower half takes the
-- maximum of two nine-way draws, and the upper half takes the minimum.
local function ordinary_count(ctx)
    local lower_half = ctx:random(streams.TEMPLE_PLAN, 2) == 0
    local first = ctx:random(streams.TEMPLE_PLAN, 9)
    local second = ctx:random(streams.TEMPLE_PLAN, 9)

    if lower_half then
        return math.max(6, 5 + math.max(first, second))
    end

    return math.min(21, 14 + math.min(first, second))
end

-- A weighted draw sees only the effective, ID-sorted definitions. Mod
-- discovery order cannot change its candidate order or draw count.
local function choose_map(ctx, catalog, rare, altar_count)
    local candidates = {}
    local total = 0

    for _, id in ipairs(catalog.main_ids()) do
        local definition = catalog.main(id)
        local eligible

        if rare then
            eligible = definition.tags.temple_rare
        else
            eligible = not definition.tags.temple_rare and
                definition.tags["temple_altars_" .. altar_count]
        end

        if eligible then
            local weight = definition.weight

            if type(weight) ~= "number" or weight < 0 or
                weight % 1 ~= 0 then
                error("Temple map " .. id .. " has invalid weight")
            end

            if weight > 0 then
                total = total + weight
                candidates[#candidates + 1] = {
                    id = id,
                    limit = total,
                }
            end
        end
    end

    if total == 0 then
        error("Temple has no eligible map for altar count " .. altar_count)
    end

    local draw = ctx:random(streams.TEMPLE_PLAN, total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.limit then
            return catalog.main(candidate.id)
        end
    end

    error("Temple weighted map draw exceeded its candidate range")
end

-- Rare maps each declare one altar count, including the zero- and
-- twenty-two-altar special maps. Reject ambiguity instead of guessing.
local function map_count(definition)
    local result

    for tag in pairs(definition.tags) do
        local number = tag:match("^temple_altars_(%d+)$")

        if number then
            if result then
                error("rare Temple map " .. definition.id ..
                    " has multiple altar counts")
            end

            result = tonumber(number)
        end
    end

    if not result then
        error("rare Temple map " .. definition.id ..
            " has no altar count")
    end

    return result
end

-- Fisher-Yates consumes the dedicated saved stream. The first N gods
-- belong to Temple; the rest retain their identities for Dungeon overflow.
local function partition(ctx, altar_count)
    local pool = temple_gods()

    if altar_count > #pool then
        error("Temple map asks for more altars than eligible gods")
    end

    for index = #pool, 2, -1 do
        local other = ctx:random(streams.TEMPLE_PLAN, index) + 1

        pool[index], pool[other] = pool[other], pool[index]
    end

    local main = {}
    local overflow = {}

    for index, id in ipairs(pool) do
        local destination = index <= altar_count and main or overflow

        destination[#destination + 1] = id
    end

    return main, overflow
end

-- Select the source rare branch before ordinary size draws. The map and
-- ordered partition are saved now so visiting Temple never rerolls them.
function plan.choose(ctx, catalog)
    catalog = catalog or default_catalog

    local rare = ctx:random(streams.TEMPLE_PLAN, 100) == 0
    local altar_count
    local definition

    if rare then
        definition = choose_map(ctx, catalog, true, 0)
        altar_count = map_count(definition)
    else
        altar_count = ordinary_count(ctx)
        definition = choose_map(ctx, catalog, false, altar_count)
    end

    local main, overflow = partition(ctx, altar_count)

    return {
        map_id = definition.id,
        altar_count = altar_count,
        main_god_ids = main,
        overflow_god_ids = overflow,
    }
end

-- A save must name an effective map and contain every eligible god once.
-- Validation does not redraw, so restored runs preserve their own RNG.
function plan.validate(chosen, catalog)
    catalog = catalog or default_catalog

    if type(chosen) ~= "table" or type(chosen.map_id) ~= "string" or
        type(chosen.altar_count) ~= "number" or
        chosen.altar_count % 1 ~= 0 or
        type(chosen.main_god_ids) ~= "table" or
        type(chosen.overflow_god_ids) ~= "table" then
        error("Temple plan has invalid fields")
    end

    local definition = catalog.main(chosen.map_id)

    if not definition or
        not definition.tags["temple_altars_" .. chosen.altar_count] then
        error("Temple plan map does not support its altar count")
    end

    local expected = {}

    for _, id in ipairs(temple_gods()) do
        expected[id] = true
    end

    if #chosen.main_god_ids ~= chosen.altar_count or
        #chosen.main_god_ids + #chosen.overflow_god_ids ~=
        #temple_gods() then
        error("Temple plan god counts do not match its map")
    end

    for _, group in ipairs({ chosen.main_god_ids,
        chosen.overflow_god_ids }) do
        for _, id in ipairs(group) do
            if type(id) ~= "string" or not expected[id] then
                error("Temple plan repeats or lacks an eligible god")
            end

            expected[id] = nil
        end
    end

    for _ in pairs(expected) do
        error("Temple plan lacks an eligible god")
    end
end

-- Go calls the same Lua validator for a restored save. The effective
-- catalog and Lua god pool decide validity; Go only checks record shapes.
function plan.validate_saved(_, input)
    plan.validate(input.temple_plan)

    return {}
end

register.policy({
    id = "world.validate_temple_plan",
    run = plan.validate_saved,
})

return plan
