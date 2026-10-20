-- Theory of operation: one Temple plan owns every overflow god for the run.
-- Source new-game rules first offer compatible multi-god vaults, then group
-- the remaining gods by the available generic map sizes. Each group draws a
-- Dungeon depth from D:3-10. The selected DES map is drawn when that floor
-- is generated, but this god/depth allocation is durable run state.
local source_catalog = require("policy.generation.altar.catalog")
local god_names = require("constants.god_names")
local limits = require("constants.overflow_altars")
local streams = require("constants.rng_streams")
local branches = require("ids.branches")
local categories = require("constants.catalog")
local map_weights = require("policy.generation.vaults.weight")

local schedule = {}

-- New-game source weights are queried at D:10, the last possible
-- overflow floor, even though each chosen group later draws D:3-10.
local function source_weight(definition)
    local dungeon = register.get(categories.BRANCHES,
        branches.BRANCH_DUNGEON)

    return map_weights.for_branch(definition,
        branches.BRANCH_DUNGEON, limits.MAX_DEPTH, dungeon.depth,
        limits.MAX_DEPTH)
end

-- Source DES god tags use lowercase names with underscores. Keep the
-- spelling derived from the same catalog displayed by the rest of Crawl.
local function god_tag(id)
    local name = god_names[id]

    if not name then
        error("overflow schedule has unknown god " .. tostring(id))
    end

    return limits.COUNT_TAG .. name:lower():gsub(" ", "_")
end

-- Ignore zero-weight maps when deciding which generic group sizes can
-- actually be selected. Catalog IDs are sorted, so file load order cannot
-- change the source schedule's seeded draws.
local function generic_weights(catalog, maximum)
    local weights = {}

    for count = 1, maximum do
        weights[count] = 0
    end

    for _, id in ipairs(catalog.ids()) do
        local definition = catalog.get(id)
        local weight = source_weight(definition)

        for count = 1, maximum do
            if definition.tags[limits.GENERIC_TAG .. count] then
                weights[count] = weights[count] + weight
            end
        end
    end

    return weights
end

-- A specialized source map must name exactly the gods its count tag asks
-- for. Some authored maps name alternatives instead; those remain available
-- at floor selection but cannot reserve one fixed group at new game time.
local function fixed_gods(definition, count, remaining)
    local found = {}

    for _, id in ipairs(remaining) do
        if definition.tags[god_tag(id)] then
            found[#found + 1] = id
        end
    end

    if #found ~= count then
        return nil
    end

    local tagged = 0

    for tag in pairs(definition.tags) do
        local suffix = tag:sub(#limits.COUNT_TAG + 1)

        if tag:sub(1, #limits.COUNT_TAG) == limits.COUNT_TAG and
            not tonumber(suffix) and
            suffix:sub(1, #limits.GENERIC_SUFFIX) ~= limits.GENERIC_SUFFIX then
            tagged = tagged + 1
        end
    end

    return tagged == count and found or nil
end

-- Save one group at its drawn source depth. The group order matters for
-- multiple vaults on a floor, while the god IDs keep their shuffle order.
local function append_group(ctx, groups, gods)
    local span = limits.MAX_DEPTH - limits.MIN_DEPTH + 1

    groups[#groups + 1] = {
        depth = limits.MIN_DEPTH + ctx:random(streams.TEMPLE_PLAN, span),
        god_ids = gods,
    }
end

-- Remove a reserved specialized group without reordering the gods that
-- remain eligible for subsequent source grouping decisions.
local function without(remaining, selected)
    local removed = {}
    local result = {}

    for _, id in ipairs(selected) do
        removed[id] = true
    end

    for _, id in ipairs(remaining) do
        if not removed[id] then
            result[#result + 1] = id
        end
    end

    return result
end

-- Give each eligible fixed multi-god source map its original weighted
-- chance against the generic maps of that size. A successful reservation
-- consumes those gods before considering the next fixed map.
local function specialized(ctx, catalog, remaining, weights, groups)
    -- Source considers size-two through size-five maps in that order. Sort
    -- definitions within each size to keep mod discovery order irrelevant.
    for count = 2, 5 do
        for _, id in ipairs(catalog.ids()) do
            local definition = catalog.get(id)
            local weight = source_weight(definition)

            if definition.tags[limits.COUNT_TAG .. count] and
                weight > 0 and #remaining >= count then
                local fixed = fixed_gods(definition, count, remaining)

                if fixed and ctx:random(streams.TEMPLE_PLAN,
                    weights[count] + weight) < weight then
                    append_group(ctx, groups, fixed)
                    remaining = without(remaining, fixed)
                end
            end
        end
    end

    return remaining
end

-- Weighted source group-size selection only offers sizes with at least
-- one generic map. A one-god group is the fallback when no multi-map fits.
local function group_size(ctx, weights, remaining)
    if remaining == 1 or
        ctx:random(streams.TEMPLE_PLAN, remaining + 1) ~= 0 then
        return 1
    end

    local total = 0

    for size = 2, remaining do
        total = total + weights[size]
    end

    if total == 0 then
        return 1
    end

    local draw = ctx:random(streams.TEMPLE_PLAN, total)

    for size = 2, remaining do
        draw = draw - weights[size]

        if draw < 0 then
            return size
        end
    end

    error("overflow group-size draw exceeded its weights")
end

-- Reserve all overflow gods once at new-game creation. Empty rare Temple
-- maps naturally schedule the entire pantheon; full ones schedule nothing.
function schedule.choose(ctx, god_ids, catalog)
    catalog = catalog or source_catalog

    local groups = {}
    local remaining = {}

    for _, id in ipairs(god_ids) do
        remaining[#remaining + 1] = id
    end

    local weights = generic_weights(catalog, #remaining)

    remaining = specialized(ctx, catalog, remaining, weights, groups)

    local index = 1

    while index <= #remaining do
        local size = group_size(ctx, weights, #remaining - index + 1)
        local gods = {}

        for offset = 0, size - 1 do
            gods[#gods + 1] = remaining[index + offset]
        end

        append_group(ctx, groups, gods)
        index = index + size
    end

    return groups
end

-- A restored schedule must cover the saved overflow partition exactly
-- once, at source depths, without drawing from the RNG or reading map IDs.
function schedule.validate(groups, god_ids)
    if type(groups) ~= "table" then
        error("Temple overflow schedule is missing")
    end

    local remaining = {}

    for _, id in ipairs(god_ids) do
        remaining[id] = true
    end

    for _, group in ipairs(groups) do
        if type(group) ~= "table" or type(group.depth) ~= "number" or
            group.depth % 1 ~= 0 or group.depth < limits.MIN_DEPTH or
            group.depth > limits.MAX_DEPTH or
            type(group.god_ids) ~= "table" or #group.god_ids == 0 then
            error("Temple overflow schedule has an invalid group")
        end

        for _, id in ipairs(group.god_ids) do
            if type(id) ~= "string" or not remaining[id] then
                error("Temple overflow schedule repeats or substitutes a god")
            end

            remaining[id] = nil
        end
    end

    for _ in pairs(remaining) do
        error("Temple overflow schedule lacks a god")
    end
end

return schedule
