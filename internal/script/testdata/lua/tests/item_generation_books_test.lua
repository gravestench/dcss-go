-- Themed book retains schools.

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
local gods = require("constants.gods")
local god_names = require("policy.religion.names")
local weapon_brands = require("constants.weapon_brands")

local test = {}

-- Zero draws make the first source school and spell entries reproducible.
local function zero_context()
    local ctx = {}

    -- Use the first book draw while asserting the named generation stream,
    -- keeping authored spell-list assertions independent of global RNG.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION, "book RNG stream")
        harness.truthy(bound > 0, "book draw bound")

        return 0
    end

    return ctx
end

-- Fixed spellbooks retain imported spell lists and level weights.
local function fixed_books_use_pinned_templates()
    local definition = catalog.get("items", ids.BOOK_CANTRIPS)

    harness.truthy(#definition.generation.spells > 0,
        "fixed book has imported spell template")
    harness.truthy(books.weight(definition, 1) > 0,
        "fixed book receives spell-level weight")
end

-- Manual generation carries both its chosen skill and point budget to the item.
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

-- Themed and level books resolve their generated spell lists from source data.
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

-- The overflow gift's slevels is a total spell-level budget, not a per-spell
-- cap. Its named owner must reach the final artefact title through the normal
-- book generation path used by a placed vault item.
local function authored_gift_books_keep_limits_and_owner()
    for _, case in ipairs({
        { numspells = 1, slevels = 1 },
        { numspells = 2, slevels = 2 },
        { numspells = 3, slevels = 4 },
    }) do
        local result = generation.roll(zero_context(), {
            kind_id = ids.BOOK_RANDART_THEME,
            depth = 5,
            quality = quality.ORDINARY,
            allow_uniques = true,
            purpose = purpose.VAULT,
            numspells = case.numspells,
            slevels = case.slevels,
            owner = god_names[gods.SIF_MUNA],
            site = "test overflow gift book",
        })
        local book = result.components[component.ITEM_RANDOM_BOOK]
        local artefact = result.components[component.ITEM_ARTEFACT]
        local levels = 0

        harness.truthy(#book.spells > 0,
            "Sif's book has a source-eligible spell")
        harness.truthy(#book.spells <= case.numspells,
            "Sif's book stays within its spell count")

        for _, spell_id in ipairs(book.spells) do
            levels = levels + catalog.get("spells", spell_id).level
        end

        harness.truthy(levels <= case.slevels,
            "Sif's book stays within its total level budget")
        harness.truthy(artefact.name:find(god_names[gods.SIF_MUNA], 1, true),
            "the owner appears in Sif's book title")
    end
end

-- A source `ego:none` weapon is deliberately plain even when ordinary item
-- generation would roll a brand. The deeper gift forces its authored brand
-- and zero enchantment after the normal generator has run.
local function authored_gift_weapons_keep_modifiers()
    local cases = {
        { kind_id = ids.WPN_SPEAR, plus = 3, ego = "" },
        { kind_id = ids.WPN_WAR_AXE, plus = 0,
            ego = weapon_brands.ANTIMAGIC },
    }

    for _, case in ipairs(cases) do
        local result = generation.roll(zero_context(), {
            kind_id = case.kind_id,
            depth = 5,
            quality = quality.ORDINARY,
            allow_uniques = false,
            purpose = purpose.VAULT,
            plus = case.plus,
            ego = case.ego,
            site = "test overflow gift weapon",
        })

        harness.equal(result.plus, case.plus)
        harness.equal(result.ego, case.ego)
    end
end

-- Cover fixed books, manuals, and random books because each carries different
-- source fields into the generated item record.
function test.run()
    fixed_books_use_pinned_templates()
    manual_retains_skill_and_points()
    random_books_retain_source_spell_lists()
    authored_gift_books_keep_limits_and_owner()
    authored_gift_weapons_keep_modifiers()
end

return test
