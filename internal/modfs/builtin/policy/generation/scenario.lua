-- Example: A fixture scenario attaches its vault records before the population pass.
local fixed = require("policy.generation.fixed")
local generated = require("policy.generation.generated")
local abyss = require("policy.generation.abyss")
local features = require("content.terrain_features")

local module = {}

-- Both startup and first-entry generation decode DES terrain through one
-- owner, so a newly entered floor retains exactly the same feature rules.
local function decode_level(ctx, level)
    level.cells = features.decode_source_rows(level.rows)

    if level.vault_records then
        level.vault_records = features.apply_vault_terrain(
            level.cells, level.vault_records, ctx, level.id)
    end

    level.rows = nil
end

-- Scenario IDs select fixed fixtures or basic generation; vault records are attached before population runs.
function module.run(ctx, input)
    local scenario_id = input.scenario_id
    local result

    if scenario_id == "fixed-dungeon-rat-quokka-lizard-v2" or
        scenario_id == "fixed-dungeon-shops-v1" then
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
        decode_level(ctx, level)
    end

    return result
end

-- Produce the destination and a parent patch as one policy result. Go checks
-- and applies both after the selected stair has passed command preparation.
function module.next(ctx, input)
    local result = generated.next(ctx, input)

    decode_level(ctx, result.level)

    return result
end

-- Startup commits only D:1 terrain and the standalone Abyss level. Every
-- later Dungeon floor is generated through the next-floor policy above.
function module.first(ctx, input)
    local result = generated.first(ctx, input)

    result.levels[#result.levels + 1] = abyss.generate(ctx)

    for _, level in ipairs(result.levels) do
        decode_level(ctx, level)
    end

    return result
end

register.policy({
    id = "world.generate_scenario",
    run = module.run,
})

register.policy({
    id = "world.generate_next_floor",
    run = module.next,
})

register.policy({
    id = "world.generate_first_floor",
    run = module.first,
})

return module
