local book_names = require("policy.item_generation.random_book_names")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local generation = require("policy.item_generation")
local harness = require("tests.harness")
local ids = require("ids.items")
local purpose = require("constants.item_generation_purpose")
local quality = require("constants.vault_item_quality")
local groups = require("constants.randart_name_groups")
local markers = require("constants.randart_name_markers")
local gods = require("constants.gods")
local schools = require("constants.spell_schools")
local streams = require("constants.rng_streams")

local test = {}

-- A zero draw selects the first weighted phrase at each catalog level.
local function first()
    return 0
end

-- Spell levels choose one of four authored title families. Level four
-- straddles the easy/moderate boundary through a source coinflip.
local function levels_choose_source_title_families()
    harness.equal(book_names.level_group(1, first),
        groups.STARTING_LEVEL_BOOK, "first-level group")
    harness.equal(book_names.level_group(3, first),
        groups.EASY_LEVEL_BOOK, "early group")
    harness.equal(book_names.level_group(4, first),
        groups.EASY_LEVEL_BOOK, "level-four easy coinflip")
    harness.equal(book_names.level_group(4, function()
        return 1
    end), groups.MODERATE_LEVEL_BOOK, "level-four moderate coinflip")
    harness.equal(book_names.level_group(5, first),
        groups.MODERATE_LEVEL_BOOK, "middle group")
    harness.equal(book_names.level_group(8, first),
        groups.DIFFICULT_LEVEL_BOOK, "late group")
end

-- Level five's first authored phrase contains @level@; the title policy
-- replaces it with the spelled-out number instead of showing raw syntax.
local function level_markers_expand()
    local title = book_names.title(first, function()
        return "Author"
    end, {
        level = 5,
        owner = "Nyx",
    }, {})

    harness.truthy(title:find("Five", 1, true),
        "level five becomes a word in the source phrase")
    harness.falsy(title:find("@", 1, true),
        "no unresolved level marker")
end

-- With no authored subject, a themed book combines the imported book noun
-- and one school-specific phrase rather than a generic syllable name.
local function themed_school_title()
    -- Decline the optional random subject, then draw each first phrase.
    local function no_subject(bound)
        if bound == 20 then
            return 1
        end

        return 0
    end

    local title = book_names.title(no_subject, function()
        return "Author"
    end, {
        first = schools.CONJURATION,
        second = schools.CONJURATION,
        level = 0,
        owner = "Nyx",
        subject = "",
        spells = {},
    }, {})

    harness.equal(title, "Nyx's Almanac of Arcane Weapons",
        "source book and school groups combine")
end

-- Xom-gifted level books sometimes use their own noun and subject rather
-- than a title based on spell difficulty.
local function xom_level_books_have_special_titles()
    local title = book_names.title(first, function()
        return "Author"
    end, {
        level = 3,
        god_id = gods.XOM,
    }, {})

    harness.truthy(title:match("^Xom's Almanac of "),
        "Xom's title uses the source book noun")
    harness.falsy(title:find("@", 1, true),
        "Xom's nested subject resolves")
end

-- An authored subject should produce a readable schoolbook title without
-- consuming a random-owner or random-subject decision.
local function explicit_owner_and_subject_form_a_book_title()
    local title = book_names.title(first, function()
        return "Author"
    end, {
        first = schools.FIRE,
        second = schools.ICE,
        level = 0,
        owner = "Nyx",
        subject = "Stars",
        spells = {},
    }, {})

    harness.equal(title, "Nyx's Almanac of Stars",
        "the source book noun joins owner and subject")

    local ending_in_s = book_names.title(first, function()
        return "Author"
    end, {
        first = schools.FIRE,
        second = schools.ICE,
        level = 0,
        owner = "Boris",
        subject = "Stars",
        spells = {},
    }, {})

    harness.equal(ending_in_s, "Boris's Almanac of Stars",
        "source possessives keep apostrophe-s after a final s")

    local with_marker = book_names.title(first, function()
        return "Author"
    end, {
        first = schools.FIRE,
        second = schools.ICE,
        level = 0,
        owner = "Boris",
        subject = "@player_name@",
        spells = {},
    }, {
        [markers.PLAYER_NAME] = "Nyx",
    })

    harness.equal(with_marker, "Boris's Almanac of Nyx",
        "authored subject markers use the catalog replacement rules")
end

-- Live generation saves source titles and hidden appearances on the same
-- artefact component used by other physical randarts.
local function generated_books_use_the_source_catalog()
    local ctx = {}

    -- A fixed item stream makes both spell-list and cosmetic-seed draws
    -- repeatable without replacing any production naming module.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION,
            "book naming shares the item stream only for its seed")
        harness.truthy(bound > 0, "positive book draw bound")

        return 0
    end

    for _, id in ipairs({
        ids.BOOK_RANDART_LEVEL,
        ids.BOOK_RANDART_THEME,
    }) do
        local result = generation.roll(ctx, {
            kind_id = id,
            depth = 5,
            quality = quality.ORDINARY,
            allow_uniques = true,
            purpose = purpose.VAULT,
            site = "test random-book names",
        })
        local artefact = result.components[component.ITEM_ARTEFACT]
        local spells = result.components[component.ITEM_RANDOM_BOOK]

        harness.truthy(#spells.spells > 0, "generated spell list remains")
        harness.falsy(artefact.name:match("^book "),
            "source title replaces the syllable fallback")
        harness.truthy(artefact.appearance:match(" book$"),
            "unidentified appearance preserves book shape")
        harness.falsy(artefact.appearance:find("non-descript", 1, true),
            "book appearance comes from weighted catalog")
        harness.falsy(artefact.name:find("@", 1, true),
            "book title has no unresolved source markers")
        harness.falsy(artefact.appearance:find("@", 1, true),
            "book appearance has no unresolved source markers")

        local repeat_result = generation.roll(ctx, {
            kind_id = id,
            depth = 5,
            quality = quality.ORDINARY,
            allow_uniques = true,
            purpose = purpose.VAULT,
            site = "repeated random-book name",
        })
        local repeated = repeat_result.components[component.ITEM_ARTEFACT]

        harness.equal(artefact.name, repeated.name,
            "same seed and spells reproduce the title")
        harness.equal(artefact.appearance, repeated.appearance,
            "same seed reproduces the hidden appearance")
    end

    harness.truthy(catalog.get(categories.RANDART_NAMES,
        groups.BOOK .. " appearance"),
        "production book appearance group is registered")
end

-- Exercise title policy and the item-generation boundary together.
function test.run()
    levels_choose_source_title_families()
    explicit_owner_and_subject_form_a_book_title()
    level_markers_expand()
    themed_school_title()
    xom_level_books_have_special_titles()
    generated_books_use_the_source_catalog()
end

return test
