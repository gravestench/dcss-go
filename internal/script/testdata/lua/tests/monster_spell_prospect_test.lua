local harness = require("tests.harness")
local prospect = require("policy.ai.spell_prospect")
local spells = require("ids.spells")
local spell_flags = require("constants.spell_flags")
local catalog = require("policy.catalog")

local test = {}

local function slot(spell_id, frequency, flags)
    return {
        spell_id = spell_id,
        frequency = frequency,
        flags = flags or {},
    }
end

local function roll(value, expected_bound)
    return function(bound)
        harness.equal(bound, expected_bound, "source roll bound")

        return value
    end
end

local function condition(hp, max_hp, distance)
    return {
        hp = hp,
        max_hp = max_hp,
        distance = distance,
        fleeing = false,
    }
end

local function source_order_and_inclusive_boundary()
    local book = {
        slots = {
            slot(spells.SPELL_MAGIC_DART, 9),
            slot(spells.SPELL_BLINK, 18),
        },
    }

    local selected, index = prospect.choose(book, condition(10, 10, 3),
        roll(9, 200))

    harness.equal(selected.spell_id, spells.SPELL_MAGIC_DART,
        "the source includes the first frequency boundary")
    harness.equal(index, 1, "first source slot index")

    selected, index = prospect.choose(book, condition(10, 10, 3),
        roll(10, 200))

    harness.equal(selected.spell_id, spells.SPELL_BLINK,
        "the next roll advances to the second slot")
    harness.equal(index, 2, "second source slot index")

    selected = prospect.choose(book, condition(10, 10, 3),
        roll(28, 200))

    harness.falsy(selected, "a roll past the book's weight does not cast")
end

local function condition_flags_do_not_consume_weight()
    local flags = require("constants.monster_spell_flags")
    local book = {
        slots = {
            slot(spells.SPELL_BLINK, 50, { flags.EMERGENCY }),
            slot(spells.SPELL_MAGIC_DART, 9, { flags.SHORT_RANGE }),
            slot(spells.SPELL_INVISIBILITY, 12,
                { flags.LONG_RANGE }),
        },
    }

    local selected = prospect.choose(book, condition(10, 30, 3),
        roll(9, 200))

    harness.equal(selected.spell_id, spells.SPELL_MAGIC_DART,
        "non-emergency excludes the first slot without weight")

    selected = prospect.choose(book, condition(9, 30, 4),
        roll(0, 200))

    harness.equal(selected.spell_id, spells.SPELL_BLINK,
        "below one third HP admits emergency slot")

    selected = prospect.choose(book, condition(30, 30, 4),
        roll(0, 200))

    harness.equal(selected.spell_id, spells.SPELL_INVISIBILITY,
        "distance four admits only the long-range slot")
end

local function silence_filters_only_source_speech_categories()
    local flags = require("constants.monster_spell_flags")
    local book = {
        slots = {
            slot(spells.SPELL_BLINK, 9, { flags.WIZARD }),
            slot(spells.SPELL_MAGIC_DART, 9, { flags.PRIEST }),
            slot(spells.SPELL_INVISIBILITY, 9, { flags.VOCAL }),
            slot(spells.SPELL_FREEZE, 18, { flags.NATURAL }),
        },
    }
    local silenced = condition(10, 10, 1)

    silenced.silenced = true

    local selected, index = prospect.choose(book, silenced,
        roll(0, 200))

    harness.equal(selected.spell_id, spells.SPELL_FREEZE,
        "silence leaves natural spells available")
    harness.equal(index, 4, "silenced speech slots consumed no weight")

    selected = prospect.choose(book, silenced, function()
        error("silenced escape slots must not draw a preference roll")
    end, spell_flags.ESCAPE)

    harness.falsy(selected, "silence also filters preferred spell choice")
end

local function preferred_spell_flags()
    local book = {
        slots = {
            slot(spells.SPELL_MAGIC_DART, 9),
            slot(spells.SPELL_BLINK, 18),
        },
    }

    local selected, index = prospect.choose(book, condition(10, 10, 3),
        roll(0, 18), spell_flags.SELF_ENCHANT)

    harness.equal(selected.spell_id, spells.SPELL_BLINK,
        "self-enchantment preference uses spell definition flags")
    harness.equal(index, 2, "preferred source slot index")

    selected = prospect.choose(book, condition(10, 10, 3),
        roll(0, 18), spell_flags.ESCAPE)

    harness.equal(selected.spell_id, spells.SPELL_BLINK,
        "escape preference uses spell definition flags")
end

local function every_committed_book_has_a_valid_prospect_shape()
    local books = catalog.all("monster_spellbooks")

    harness.equal(#books, 285, "committed source book count")

    for _, book in ipairs(books) do
        local selected, index = prospect.choose(book,
            condition(10, 10, 4), roll(199, 200))

        if selected then
            harness.equal(book.slots[index].spell_id, selected.spell_id,
                book.id .. " selected source slot")
        end
    end
end

function test.run()
    source_order_and_inclusive_boundary()
    condition_flags_do_not_consume_weight()
    silence_filters_only_source_speech_categories()
    preferred_spell_flags()
    every_committed_book_has_a_valid_prospect_shape()
end

return test
