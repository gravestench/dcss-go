-- The committed overflow family must include every source NAME as an
-- effective DES file. The ordinary extra-vault catalog excludes this family
-- until its scheduled god assignment chooses a specific map.
local catalog = require("policy.generation.altar.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local names = require("constants.vault_feature_names")
local ordinary = require("policy.generation.vaults.catalog")

local test = {}

-- Run an actual parsed hook with a minimal record sink. This checks the DES
-- reference and production Lua together, without copying their definitions.
local function records_for(id, method)
    local definition = catalog.get(id)
    local found = false
    local records = {}
    local api = {}

    function api:record(kind, arguments)
        records[#records + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN and
            operation.argument == method then
            hooks.run(definition, method, api)
            found = true
        end
    end

    harness.truthy(found, id .. " has its source-position " .. method .. " hook")

    return records
end

-- The source's repeated renames share a Lua implementation but every map
-- must retain its own hook, so no vault silently loses its displayed name.
local function assert_feature_names()
    local gold_maps = {
        "grunt_gozag_statues",
        "grunt_gozag_breadcrumbs",
        "nicolae_gozag_conspicuous_consumption",
        "grunt_temple_overflow_opulence",
        "grunt_temple_overflow_gold_and_silver",
    }

    for _, id in ipairs(gold_maps) do
        local records = records_for(id, "features.golden_statue")

        harness.equal(#records, 1, id .. " records one golden statue name")
        harness.equal(records[1].kind, effects.FEATURE_NAME)
        harness.equal(records[1].arguments.feature, features.GRANITE_STATUE)
        harness.equal(records[1].arguments.name, names.GOLDEN_STATUE)
    end

    local cases = {
        { "grunt_temple_overflow_gold_and_silver", "features.silver_wall",
            features.METAL_WALL, names.SILVER_WALL },
        { "nemelex_diamond_rough_becter", "features.white_crystal_wall",
            features.CRYSTAL_WALL, names.WHITE_CRYSTAL_WALL },
        { "nicolae_yredelemnul_corpse_copse", "features.dead_tree",
            features.TREE, names.DEAD_TREE },
        { "gammafunk_temple_of_torment", "features.sarcophagus",
            features.GRANITE_STATUE, names.SARCOPHAGUS },
        { "worldfamousw_hep_ancestral_shrine", "features.gravestone",
            features.GRANITE_STATUE, names.GRAVESTONE },
        { "worldfamousw_hep_ancestral_shrine", "features.dead_tree",
            features.TREE, names.DEAD_TREE },
    }

    for _, entry in ipairs(cases) do
        local records = records_for(entry[1], entry[2])

        harness.equal(#records, 1, entry[1] .. " records one feature name")
        harness.equal(records[1].kind, effects.FEATURE_NAME)
        harness.equal(records[1].arguments.feature, entry[3])
        harness.equal(records[1].arguments.name, entry[4])
    end
end

-- Delayed decay must remain attached to the source D/E corpse glyphs instead
-- of replacing them with permanent scenery during map parsing.
local function assert_dancefloor_decay()
    local records = records_for(
        "nicolae_uskayaw_murder_on_the_dancefloor", "decay_dancers")

    harness.equal(#records, 1)
    harness.equal(records[1].kind, effects.DELAYED_DECAY)
    harness.equal(records[1].arguments.glyph, "DE")
    harness.equal(records[1].arguments.alternatives, "random corpse")
end

-- Parsing the full family catches broken directives and missing named hooks
-- at startup rather than only when a rare altar map is selected.
function test.run()
    local ids = catalog.ids()

    harness.equal(#ids, 232,
        "all source overflow altar definitions are committed")

    local previous = ""

    for _, id in ipairs(ids) do
        harness.truthy(id > previous,
            "overflow IDs are unique and sorted")
        harness.equal(catalog.get(id).id, id,
            "the catalog returns its parsed source definition")
        previous = id
    end

    local ashenzari = catalog.get("ashenzari_altar_1")

    harness.truthy(ashenzari.tags.temple_overflow_ashenzari,
        "specialized god tags survive the source import")
    harness.truthy(#ashenzari.rows > 0,
        "source altar geometry remains in DES MAP rows")

    local selectable = pcall(ordinary.get, ashenzari.id)

    harness.falsy(selectable,
        "unported overflow maps cannot enter ordinary vault selection")

    assert_feature_names()
    assert_dancefloor_decay()
end

return test
