local purpose = require("constants.item_generation_purpose")
local streams = require("constants.rng_streams")
local books = require("policy.item_generation.books")
local catalog = require("policy.catalog")
local component = require("constants.component")
local generation = require("policy.item_generation")
local harness = require("tests.harness")
local ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local skills = require("ids.skills")

local test = {}

local function zero_context()
    local ctx = {}

    function ctx:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION, "book RNG stream")
        harness.truthy(bound > 0, "book draw bound")

        return 0
    end

    return ctx
end

local function fixed_books_use_pinned_templates()
    local definition = catalog.get("items", ids.BOOK_CANTRIPS)

    harness.truthy(#definition.generation.spells > 0,
        "fixed book has imported spell template")
    harness.truthy(books.weight(definition, 1) > 0,
        "fixed book receives spell-level weight")
end

local function manual_retains_skill_and_points()
    local result = generation.roll(zero_context(), {
        kind_id = ids.BOOK_MANUAL,
        depth = 1,
        quality = quality.ORDINARY,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "test manual",
    })
    local manual = result.components[component.ITEM_MANUAL]
    local known = result.components[component.ITEM_IDENTIFICATION]

    harness.equal(manual.skill_id, skills.SK_SPELLCASTING,
        "source first magic manual skill")
    harness.equal(manual.points, 2000, "source minimum manual points")
    harness.truthy(known.known_type, "manual preidentified")
end

local function random_books_retain_source_spell_lists()
    local theme = generation.roll(zero_context(), {
        kind_id = ids.BOOK_RANDART_THEME,
        depth = 5,
        quality = quality.ORDINARY,
        allow_uniques = true,
        purpose = purpose.VAULT,
        site = "test themed book",
    })
    local level = generation.roll(zero_context(), {
        kind_id = ids.BOOK_RANDART_LEVEL,
        depth = 5,
        quality = quality.ORDINARY,
        allow_uniques = true,
        purpose = purpose.VAULT,
        site = "test level book",
    })
    local themed_spells = theme.components[component.ITEM_RANDOM_BOOK]
    local level_spells = level.components[component.ITEM_RANDOM_BOOK]

    harness.truthy(#themed_spells.spells > 0, "themed book has spells")
    harness.truthy(themed_spells.theme ~= "", "themed book retains schools")
    harness.equal(level_spells.level, 1, "early level book spell level")

    for _, spell_id in ipairs(level_spells.spells) do
        harness.equal(catalog.get("spells", spell_id).level, 1,
            "level book uses its fixed spell level")
    end
end

function test.run()
    fixed_books_use_pinned_templates()
    manual_retains_skill_and_points()
    random_books_retain_source_spell_lists()
end

return test
