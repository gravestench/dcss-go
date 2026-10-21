local roster = require("policy.population.roster")
local generated = require("policy.save.generated_levels")
local abyss = require("policy.save.abyss_levels")
local world_abyss = require("policy.world.abyss")
local branches = require("ids.branches")

local population_id = "fixed-dungeon-population-v1"
local generated_id = "generated-dungeon-basic-v1"

local module = {}

-- Validate scenario ownership and level monster budgets before accepting restored level data.
-- Example: module.run(nil, { scenario_id = scenario_id, levels = levels }) checks branch ownership.
function module.run(_, input)
    local scenario_id = input.scenario_id
    local levels = input.levels
    local by_id = {}

    -- Save rosters and level budgets use the same recognized scenarios.
    roster.allowed(scenario_id, branches.BRANCH_DUNGEON)

    for _, level in ipairs(levels) do
        if by_id[level.id] then
            error("duplicate saved level " .. tostring(level.id))
        end

        by_id[level.id] = level
        local choices = level.initial_monsters

        if level.id == world_abyss.level_id then
            if level.branch_id ~= branches.BRANCH_ABYSS then
                error("Abyss level has the wrong branch owner")
            end

            abyss.validate(level)
        elseif scenario_id == generated_id then
            -- The branch validator below checks source ownership, depth,
            -- and topology for every generated ordinary floor.
            -- Branch source pools include NO_MONSTER rolls; a spent budget
            -- can therefore create fewer actors than Dungeon's baseline.
            local minimum = level.branch_id ==
                branches.BRANCH_DUNGEON and choices or 0

            if (level.initial_actors < minimum or
                    level.initial_actors > 4 * choices) then
                error("generated level " .. level.id ..
                    " has invalid initial actor count")
            end
        elseif scenario_id == population_id then
            if level.branch_id ~= branches.BRANCH_DUNGEON then
                error("Dungeon level has the wrong branch owner")
            end

            -- Generated floors are saved only after their first-entry
            -- population transaction, so every existing floor has actors.
            if (level.initial_actors < choices or
                    level.initial_actors > 4 * choices) then
                error("Dungeon:" .. level.id .. " has invalid initial actor count")
            end
        else
            if level.branch_id ~= branches.BRANCH_DUNGEON then
                error("fixture Dungeon level has the wrong branch owner")
            end

            if level.initial_actors ~= 0 then
                error("fixture Dungeon:" .. level.id ..
                    " has an initial actor count")
            end
        end
    end

    if scenario_id == generated_id then
        generated.validate(levels, by_id, input.branch_schedule,
            input.pan_state)
        return {}
    end

    if not by_id[1] or not by_id[2] or
        not by_id[world_abyss.level_id] then
        error("fixed Dungeon save needs D:1-2 and the Abyss")
    end

    for _, level in ipairs(levels) do
        if level.id ~= world_abyss.level_id then

            for _, link in ipairs(level.stairs) do
                if link.unavailable ~= "" then
                    error("fixed Dungeon:" .. level.id .. " has an unavailable stair")
                end
            end

            if scenario_id == population_id then
                if level.initial_monsters ~= 2 then
                    error("fixed Dungeon:" .. level.id .. " has invalid monster budget")
                end
            elseif level.initial_monsters ~= 0 then
                error("fixture Dungeon:" .. level.id .. " has a monster budget")
            end
        end
    end

    return {}
end

register.policy({
    id = "save.validate_scenario_levels",
    run = module.run,
})

return module
