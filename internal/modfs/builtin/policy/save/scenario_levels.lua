local roster = require("policy.population.roster")
local generated = require("policy.save.generated_levels")

local population_id = "fixed-dungeon-population-v1"
local generated_id = "generated-dungeon-basic-v1"

register.policy({
    id = "save.validate_scenario_levels",
    run = function(_, input)
        local scenario_id = input.scenario_id
        local levels = input.levels
        local by_id = {}

        -- Save rosters and level budgets use the same recognized scenarios.
        roster.allowed(scenario_id)

        for _, level in ipairs(levels) do
            by_id[level.id] = level
            local choices = level.initial_monsters

            if scenario_id == generated_id or scenario_id == population_id then
                if level.initial_actors < choices or level.initial_actors > 4 * choices then
                    error("Dungeon:" .. level.id .. " has invalid initial actor count")
                end
            elseif level.initial_actors ~= 0 then
                error("fixture Dungeon:" .. level.id .. " has an initial actor count")
            end
        end

        if scenario_id == generated_id then
            generated.validate(levels, by_id)
            return {}
        end

        for _, level in ipairs(levels) do
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

        return {}
    end,
})
