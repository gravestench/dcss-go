-- All 34 concrete clouds remain present when catalog entries are ordered by ID;
-- selector sentinels and incomplete cloud definitions remain invalid.

local harness = require("tests.harness")
local categories = require("constants.catalog")
local content = require("policy.catalog")
local ids = require("ids.clouds")
local selectors = require("constants.cloud_selectors")

local test = {}

local concrete_ids = {
    ids.CLOUD_FIRE,
    ids.CLOUD_MEPHITIC,
    ids.CLOUD_COLD,
    ids.CLOUD_POISON,
    ids.CLOUD_BLACK_SMOKE,
    ids.CLOUD_GREY_SMOKE,
    ids.CLOUD_BLUE_SMOKE,
    ids.CLOUD_PURPLE_SMOKE,
    ids.CLOUD_TLOC_ENERGY,
    ids.CLOUD_FOREST_FIRE,
    ids.CLOUD_STEAM,
    ids.CLOUD_GLOOM,
    ids.CLOUD_INK,
    ids.CLOUD_PETRIFY,
    ids.CLOUD_HOLY,
    ids.CLOUD_MIASMA,
    ids.CLOUD_MIST,
    ids.CLOUD_CHAOS,
    ids.CLOUD_RAIN,
    ids.CLOUD_MUTAGENIC,
    ids.CLOUD_MAGIC_TRAIL,
    ids.CLOUD_VORTEX,
    ids.CLOUD_DUST,
    ids.CLOUD_SPECTRAL,
    ids.CLOUD_ACID,
    ids.CLOUD_STORM,
    ids.CLOUD_NEGATIVE_ENERGY,
    ids.CLOUD_FLUFFY,
    ids.CLOUD_XOM_TRAIL,
    ids.CLOUD_SALT,
    ids.CLOUD_GOLD_DUST,
    ids.CLOUD_EMBERS,
    ids.CLOUD_FLAME,
    ids.CLOUD_DEGENERATION,
}

-- Verify validation fails for the intended missing field, not an unrelated catalog error.
local function expect_invalid(catalog, definition, reason)
    local okay, message = pcall(catalog.definition, definition)

    harness.falsy(okay, "invalid cloud must be rejected")
    harness.truthy(tostring(message):find(reason, 1, true),
        "error must name " .. reason)
end

-- Check exact cloud membership independently of registration order, then verify source metadata.
function test.run()
    local catalog = require("policy.clouds.catalog")
    local clouds = content.all(categories.CLOUDS)

    harness.equal(#clouds, 34, "pinned source concrete cloud count")

    local expected = {}
    local seen = {}

    for _, id in ipairs(concrete_ids) do
        expected[id] = true
    end

    -- Catalog ordering is by stable ID; membership is checked independently
    -- so moving a cloud in the old source table does not change coverage.
    local previous_id

    for _, definition in ipairs(clouds) do
        harness.truthy(expected[definition.id],
            "unexpected concrete cloud " .. definition.id)
        harness.falsy(seen[definition.id],
            "duplicate concrete cloud " .. definition.id)

        if previous_id then
            harness.truthy(previous_id < definition.id,
                "cloud catalog IDs are ascending")
        end

        seen[definition.id] = true
        previous_id = definition.id
        harness.truthy(definition.name ~= "", "cloud has a name")
        harness.truthy(definition.color ~= "", "cloud has a color")
        harness.truthy(type(definition.opaque) == "boolean",
            "cloud has opacity")
        harness.truthy(type(definition.damage) == "table",
            "cloud has source damage metadata")
        harness.truthy(type(definition.spread_rate) == "number",
            "cloud has source spread rate")
    end

    for _, id in ipairs(concrete_ids) do
        harness.truthy(seen[id], "missing concrete cloud " .. id)
    end

    local fire = content.get(categories.CLOUDS, ids.CLOUD_FIRE)
    local steam = content.get(categories.CLOUDS, ids.CLOUD_STEAM)

    harness.equal(fire.name, "flame", "source fire name")
    harness.equal(fire.damage.base, 6, "source fire base damage")
    harness.equal(fire.damage.random, 16, "source fire random damage")
    harness.falsy(fire.opaque, "source fire is transparent")
    harness.equal(steam.spread_rate, 22, "source steam spread")
    harness.truthy(steam.opaque, "source steam obscures sight")

    for _, selector in ipairs({
        selectors.NONE,
        selectors.RANDOM_SMOKE,
        selectors.RANDOM,
        selectors.DEBUGGING,
    }) do
        local okay = pcall(content.get, categories.CLOUDS, selector)

        harness.falsy(okay, "selector is not a concrete cloud")
    end

    expect_invalid(catalog, {
        id = "CLOUD_TEST",
        name = "test",
        color = "WHITE",
        opaque = false,
        harmless = false,
        spread_rate = 0,
        damage = {
            base = 0,
            random = 0,
            extra_player = false,
        },
    }, "effect")

    local missing_harm = {}

    for key, value in pairs(fire) do
        missing_harm[key] = value
    end

    missing_harm.harmless = nil
    expect_invalid(catalog, missing_harm, "harmless")

    local missing_color = {}

    for key, value in pairs(fire) do
        missing_color[key] = value
    end

    missing_color.color = "NOT_A_COLOR"
    missing_color.console_color = nil
    expect_invalid(catalog, missing_color, "console color")
end

return test
