-- A generated Dungeon floor must preserve the overflow gods assigned at
-- new game. The saved Temple plan is the authority; vault map records show
-- where those gods were actually placed. This check never redraws a map.
local altar_catalog = require("policy.generation.altar.catalog")
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local glyphs = require("constants.vault_glyphs")
local temple_plan = require("policy.generation.temple.plan")

local overflow_altars = {}

-- Group the saved identities by Dungeon depth while rejecting an altered
-- schedule through the same policy that accepted it at new-game creation.
local function expected_by_depth(chosen)
    temple_plan.validate(chosen)

    local expected = {}

    for _, group in ipairs(chosen.overflow_schedule) do
        expected[group.depth] = expected[group.depth] or {}

        for _, id in ipairs(group.god_ids) do
            expected[group.depth][id] = true
        end
    end

    return expected
end

-- An altar record is valid only when its source map was placed on this
-- floor, its god is scheduled here, and no other altar claimed that god.
local function validate_level(level, scheduled)
    local placed_ids = {}
    local found = {}

    for _, id in ipairs(level.vault_ids or {}) do
        placed_ids[id] = true
    end

    for _, record in ipairs(level.vault_records or {}) do
        local source = altar_catalog.get(record.source_id)

        if source and record.identity == glyphs.terrain.B then
            local id = record.arguments and record.arguments.god_id

            if record.kind ~= effects.SOURCE_FEATURE or
                record.pending or record.overridden or
                not placed_ids[record.source_id] or
                not scheduled[id] or found[id] then
                error("Dungeon overflow altar disagrees with saved plan")
            end

            found[id] = true
        end
    end

    for id in pairs(scheduled) do
        if not found[id] then
            error("Dungeon overflow altar is missing scheduled god " .. id)
        end
    end
end

-- An unvisited Dungeon floor has no record yet. Every reached floor in the
-- source overflow band must account for its full scheduled god set.
function overflow_altars.validate(_, input)
    local by_depth = expected_by_depth(input.temple_plan)

    for _, level in ipairs(input.levels or {}) do
        if level.branch_id == branches.BRANCH_DUNGEON then
            validate_level(level, by_depth[level.id] or {})
        end
    end

    return {}
end

register.policy({
    id = "save.validate_overflow_altars",
    run = overflow_altars.validate,
})

return overflow_altars
