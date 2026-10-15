local fixed = require("policy.generation.fixed")
local generated = require("policy.generation.generated")
local abyss = require("policy.generation.abyss")

register.policy({
    id = "world.generate_scenario",
    run = function(ctx, input)
        local scenario_id = input.scenario_id
        local result

        if scenario_id == "fixed-dungeon-rat-quokka-lizard-v2" then
            result = fixed.generate(false)
        elseif scenario_id == "fixed-dungeon-population-v1" then
            result = fixed.generate(true)
        elseif scenario_id == "generated-dungeon-basic-v1" then
            result = generated.generate(ctx)
        else
            error(string.format("unsupported scenario ID %q", tostring(scenario_id)))
        end

        result.levels[#result.levels + 1] = abyss.generate(ctx)

        return result
    end,
})
