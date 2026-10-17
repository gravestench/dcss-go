local fixed = require("policy.generation.fixed")
local generated = require("policy.generation.generated")
local abyss = require("policy.generation.abyss")
local features = require("content.terrain_features")

local module = {}

function module.run(ctx, input)
    local scenario_id = input.scenario_id
    local result

    if scenario_id == "fixed-dungeon-rat-quokka-lizard-v2" then
        result = fixed.generate(false)
    elseif scenario_id == "fixed-dungeon-population-v1" then
        result = fixed.generate(true)
    elseif scenario_id == "generated-dungeon-basic-v1" then
        result = generated.generate(ctx, input)
    else
        error(string.format("unsupported scenario ID %q", tostring(scenario_id)))
    end

    result.levels[#result.levels + 1] = abyss.generate(ctx)

    for _, level in ipairs(result.levels) do
        level.cells = features.decode_source_rows(level.rows)
        if level.vault_records then
            level.vault_records = features.apply_vault_terrain(
                level.cells, level.vault_records, ctx, level.id)
        end
        level.rows = nil
    end

    return result
end

register.policy({
    id = "world.generate_scenario",
    run = module.run,
})

return module
