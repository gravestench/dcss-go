-- Theory of operation: the Abyss replaces one level in the middle of an
-- action. Its DES records must become ECS entities against the staged map,
-- before that action commits. This policy projects only pending authored
-- records into the ordinary vault materializer, then marks those records
-- on the detached next region. A failed action discards both the entities
-- and their record transitions.
local abyss = require("constants.abyss")
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local vaults = require("policy.population.vaults")
local ambient = require("policy.population.ambient")
local roster = require("policy.population.roster")
local scenarios = require("constants.scenarios")

local population = {}

-- The host stores record positions as one-based indices even though map
-- coordinates are zero-based. Preserve this origin for save provenance.
local function pending_records(level)
    local records = {}

    for index, source in ipairs(level.vault_records or {}) do
        local arguments = source.arguments or {}
        local kind = source.kind
        local selected = arguments.kind_id and arguments.kind_id ~= ""
        local monster_fallback = kind == effects.MONSTER and
            (arguments.monster_slots or 0) > 1
        local effect = kind == effects.ITEM or
            kind == effects.MONSTER or
            kind == effects.MARKER or
            kind == effects.FEATURE or
            kind == effects.SOURCE_FEATURE

        if source.pending ~= false and not source.overridden and effect and
            (selected or monster_fallback or
                kind == effects.MARKER or
                kind == effects.FEATURE or
                kind == effects.SOURCE_FEATURE) then
            local record = {}

            for name, value in pairs(source) do
                record[name] = value
            end

            record.index = index
            record.source_id = source.vault_id
            records[#records + 1] = record
        end
    end

    return records
end

-- Reuse the source-aware vault factory and its unique, item, band, and
-- marker handling. The runtime's pending terrain view is already the new
-- region when this function is called.
function population.materialize(ctx, level)
    local view = {
        id = abyss.LEVEL_ID,
        branch_id = branches.BRANCH_ABYSS,
        local_depth = level.local_depth,
        width = abyss.WIDTH,
        height = abyss.HEIGHT,
        entry_x = level.entry_x or abyss.CENTRE_X,
        entry_y = level.entry_y or abyss.CENTRE_Y,
        vault_records = pending_records(level),
        budget = level.initial_monsters or 0,
    }
    local excluded = {}

    for _, point in ipairs(level.spawn_exclusions or {}) do
        excluded[point.x .. ":" .. point.y] = true
    end

    local count, materialized = vaults.materialize(ctx, view, excluded)

    ctx:mark_region_records(abyss.LEVEL_ID, {
        entries = materialized,
    })

    if view.budget > 0 then
        local allowed = roster.allowed(scenarios.GENERATED_DUNGEON_BASIC,
            branches.BRANCH_ABYSS)

        count = count + ambient.populate(ctx, view, allowed,
            scenarios.GENERATED_DUNGEON_BASIC)
    end

    ctx:add_region_actors(abyss.LEVEL_ID, count)

    return count
end

return population
