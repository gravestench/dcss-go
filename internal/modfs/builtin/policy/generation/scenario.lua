local fixed = require("policy.generation.fixed")
local generated = require("policy.generation.generated")

register.policy({
    id = "world.generate_scenario",
    run = function(ctx, input)
        local scenario_id = input.scenario_id

        if scenario_id == "fixed-dungeon-rat-quokka-lizard-v2" then
            return fixed.generate(false)
        end

        if scenario_id == "fixed-dungeon-population-v1" then
            return fixed.generate(true)
        end

        if scenario_id == "generated-dungeon-basic-v1" then
            return generated.generate(ctx)
        end

        error(string.format("unsupported scenario ID %q", tostring(scenario_id)))
    end,
})
