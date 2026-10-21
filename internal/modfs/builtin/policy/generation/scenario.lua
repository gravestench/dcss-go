-- Example: A fixture scenario attaches its vault records before the population pass.
local fixed = require("policy.generation.fixed")
local generated = require("policy.generation.generated")
local abyss = require("policy.generation.abyss")
local pan = require("policy.generation.pan.region")
local features = require("content.terrain_features")
local transporters = require("policy.generation.transporters")
local item_ids = require("ids.items")

local module = {}

-- Both startup and first-entry generation decode DES terrain through one
-- owner, so a newly entered floor retains exactly the same feature rules.
local function decode_level(ctx, level)
    level.cells = features.decode_source_rows(level.rows)

    if level.vault_records then
        level.vault_records = features.apply_vault_terrain(
            level.cells, level.vault_records, ctx, level.id)
        transporters.resolve(level)
    end

    level.rows = nil
end

-- Fixed fixtures keep their authored maps for engine tests. Ordinary play
-- uses first() and next() so later Dungeon layouts draw from live RNG.
function module.run(ctx, input)
    local scenario_id = input.scenario_id
    local result

    if scenario_id == "fixed-dungeon-rat-quokka-lizard-v2" or
        scenario_id == "fixed-dungeon-shops-v1" then
        result = fixed.generate(false)
    elseif scenario_id == "fixed-dungeon-population-v1" then
        result = fixed.generate(true)
    else
        error(string.format("unsupported scenario ID %q", tostring(scenario_id)))
    end

    result.levels[#result.levels + 1] = abyss.generate(ctx)

    -- The fixed benchmark retains its authored coordinates. Population
    -- receives the same item intent format as live Dungeon generation.
    result.starting_items = {
        {
            kind_id = item_ids.POT_CURING,
            level_id = 1,
            x = result.curing.x,
            y = result.curing.y,
        },

        {
            kind_id = item_ids.POT_HEAL_WOUNDS,
            level_id = 2,
            x = result.heal.x,
            y = result.heal.y,
        },

        {
            kind_id = item_ids.POT_HASTE,
            level_id = 2,
            x = result.haste.x,
            y = result.haste.y,
        },
    }

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

-- A Pan portal requests one complete replacement region. Return it through
-- the same terrain decoder as first-entry branch floors so the generic Go
-- installer never has to interpret source DES glyphs or Pan map IDs.
function module.pan(ctx, input)
    local level = pan.generate(ctx, input)

    decode_level(ctx, level)

    return {
        level = level,
    }
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

register.policy({
    id = "world.generate_pan_region",
    run = module.pan,
})

return module
