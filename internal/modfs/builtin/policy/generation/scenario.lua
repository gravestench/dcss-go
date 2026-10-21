-- Example: A fixture scenario attaches its vault records before the population pass.
local fixed = require("policy.generation.fixed")
local generated = require("policy.generation.generated")
local abyss = require("policy.generation.abyss")
local pan = require("policy.generation.pan.region")
local hell_vestibule = require("policy.generation.hell.vestibule")
local features = require("content.terrain_features")
local transporters = require("policy.generation.transporters")
local item_ids = require("ids.items")
local component = require("constants.component")
local runes = require("policy.character.runes")
local nearest = require("policy.generation.nearest")
local terrain = require("constants.terrain")

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

-- DCSS rewrites every upward stone stair and escape hatch on a Pan
-- level into a transit portal after vault terrain is resolved. The source
-- DES still owns the stair glyph; this branch pass gives it Pan's travel
-- meaning and prevents an unlinked ordinary stair from entering the save.
local function fixup_pan_stairs(level)
    for _, row in ipairs(level.cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_STONE_STAIRS_UP_I then
                row[x] = terrain.DNGN_TRANSIT_PANDEMONIUM
            end
        end
    end
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
    -- Live portal travel supplies only saved region history. Read character
    -- identity and collected runes from the player ECS component so a rune
    -- picked up on this region changes the next region's source hooks.
    if input.collected_runes == nil then
        local player = ctx:player()
        local identity = ctx:get(player, component.PLAYER)
        local progress = ctx:get(player, component.PLAYER_RUNES)

        if not identity or not progress then
            error("Pan generation needs player identity and rune progress")
        end

        input.species_id = identity.species_id
        input.player_name = identity.name
        input.collected_runes = progress.collected
        input.pan_rune_count = runes.pan_count(ctx, player)
    end

    local level = pan.generate(ctx, input)

    decode_level(ctx, level)
    fixup_pan_stairs(level)

    -- KFEAT and BORDER_FILL records can replace a raw floor glyph after
    -- carving. Select the arrival from the final typed terrain grid.
    local entry = nearest.open_feature(level.cells, {
        x = level.entry_x,
        y = level.entry_y,
    }, terrain.DNGN_FLOOR)

    level.entry_x = entry.x
    level.entry_y = entry.y

    return {
        level = level,
    }
end

-- Hell's rootless first floor owns its source map and return arches. The
-- generic staging kernel installs its decoded level like any other floor.
function module.hell_vestibule(ctx, input)
    return hell_vestibule.generate(ctx, input)
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

register.policy({
    id = "world.generate_hell_vestibule",
    run = module.hell_vestibule,
})

return module
