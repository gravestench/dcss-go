-- One effective book catalog must drive every player-spell consumer.
-- These tests use copied production definitions as overlay fixtures, so
-- a schema change is not duplicated in a test-only content declaration.
local books = require("policy.magic.player_book_catalog")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local effects = require("policy.magic.effects.registry")
local harness = require("tests.harness")
local innate = require("policy.character.innate_spells")
local item_ids = require("ids.items")
local jobs = require("ids.jobs")
local random_books = require("policy.item_generation.random_books")
local scopes = require("constants.spell_scopes")
local spell_ids = require("ids.spells")
local spell_scope = require("policy.magic.player_scope")
local species_ids = require("ids.species")
local wanderer = require("policy.character.wanderer_spells")
local skills = require("ids.skills")

local test = {}
local mod_spell_id = "SPELL_TEST_BOOK_OVERLAY"

-- The bundled book files encode the 109 source player-book spells once.
-- This assertion guards the migration from the former frozen ID table.
local function bundled_book_set()
    local ids = books.ids()
    local count = 0
    local ordered = {}

    for id in pairs(ids) do
        count = count + 1
        ordered[#ordered + 1] = id
    end

    table.sort(ordered)

    -- Pinned from the deleted source list, after sorting its 109 IDs and
    -- joining them with newlines. Count alone misses a swapped spell ID.
    local hash = 0

    for byte in (table.concat(ordered, "\n")):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    harness.equal(count, 109, "source book membership count")
    harness.equal(hash, 2762886587, "complete source book membership")
    harness.truthy(ids[spell_ids.SPELL_MAGIC_DART],
        "Minor Magic contributes Magic Dart")
end

-- Scope may ask about hundreds of spells in one session. Once registration
-- closes, repeated membership reads must reuse the derived catalog view.
local function frozen_book_set_is_reused()
    harness.truthy(register.frozen(), "Lua tests run after registration")

    local original_get = register.get
    local reads = 0

    register.get = function(category, id)
        reads = reads + 1

        return original_get(category, id)
    end

    local okay, failure = pcall(function()
        local first = books.ids()
        local after_first = reads

        first[spell_ids.SPELL_MAGIC_DART] = nil

        local second = books.ids()

        harness.truthy(after_first > 0, "first read builds the view")
        harness.equal(reads, after_first, "second read reuses the view")
        harness.truthy(second[spell_ids.SPELL_MAGIC_DART],
            "the caller cannot mutate cached membership")
    end)

    register.get = original_get

    if not okay then
        error(failure)
    end
end

-- Simulate one effective mod layer: add a level-one spell to a fixed book
-- and remove Magic Dart from every book without changing Lua load order.
local function with_book_overlay(callback)
    local original_get = register.get
    local original_ids = register.ids

    register.ids = function(category)
        local ids = original_ids(category)

        if category == categories.SPELLS then
            ids[#ids + 1] = mod_spell_id
        end

        return ids
    end

    register.get = function(category, id)
        if category == categories.SPELLS and id == mod_spell_id then
            local definition = original_get(category,
                spell_ids.SPELL_MAGIC_DART)

            definition.id = mod_spell_id
            definition.numeric_id = nil

            return definition
        end

        local definition = original_get(category, id)

        if category == categories.ITEMS and
            definition.generation and
            definition.generation.spells then
            local retained = {}

            for _, spell_id in ipairs(definition.generation.spells) do
                if spell_id ~= spell_ids.SPELL_MAGIC_DART then
                    retained[#retained + 1] = spell_id
                end
            end

            if id == item_ids.BOOK_MINOR_MAGIC then
                retained[#retained + 1] = mod_spell_id
            end

            definition.generation.spells = retained
        end

        return definition
    end

    local okay, failure = pcall(callback)

    register.get = original_get
    register.ids = original_ids

    if not okay then
        error(failure)
    end
end

-- The same add/remove operation must affect scope and resolver coverage.
local function overlay_changes_scope_and_coverage()
    with_book_overlay(function()
        local ids = books.ids()
        local ordered = books.ordered()
        local missing = effects.missing()
        local found = false

        harness.truthy(ids[mod_spell_id], "mod book spell is included")
        harness.truthy(not ids[spell_ids.SPELL_MAGIC_DART],
            "removed book spell is excluded")
        harness.equal(ordered[#ordered].id, mod_spell_id,
            "mod spells without source ordinals sort last")
        harness.equal(spell_scope.of(mod_spell_id), scopes.BOOK)
        harness.equal(spell_scope.of(spell_ids.SPELL_MAGIC_DART),
            scopes.NONE)

        for _, id in ipairs(missing) do
            found = found or id == mod_spell_id
        end

        harness.truthy(found,
            "effect coverage includes a modded player-book spell")
    end)
end

-- A Djinni schedule and Wanderer gift must use the same overlay pool.
-- Zero reservoir rolls choose the final eligible source-ordered entry.
local function overlay_changes_character_spells(ctx)
    with_book_overlay(function()
        local species = catalog.get(categories.SPECIES,
            species_ids.SP_DJINNI)
        local player = ctx:create()
        local game = setmetatable({}, { __index = ctx })

        ctx:add(player, component.PLAYER, {
            species_id = species_ids.SP_DJINNI,
            job_id = jobs.JOB_WANDERER,
        })

        function game:player()
            return player
        end

        function game:random(_, bound)
            harness.truthy(bound > 0, "spell draw has candidates")

            return 0
        end

        local future = innate.generate(game, species, {})
        local gift = wanderer.gift(game, species,
            skills.SK_CONJURATIONS, true)

        harness.equal(future[1], mod_spell_id,
            "Djinni future spells use the effective book")
        harness.equal(gift[1], mod_spell_id,
            "Wanderer gifts use the effective book")
    end)
end

-- A random level book must accept the mod spell and avoid a nil numeric-ID
-- comparison when the source-numbered and modded candidates are sorted.
local function overlay_changes_random_books()
    with_book_overlay(function()
        local game = {}
        local result = {
            components = {},
        }

        function game:random(_, bound)
            harness.truthy(bound > 0, "book draw has candidates")

            return bound - 1
        end

        random_books.roll(game,
            catalog.get(categories.ITEMS, item_ids.BOOK_RANDART_LEVEL),
            {
                depth = 1,
                acquirement_level = 1,
            },
            result)

        local spell_list = result.components[component.ITEM_RANDOM_BOOK].spells
        local found = false

        for _, id in ipairs(spell_list) do
            found = found or id == mod_spell_id
        end

        harness.truthy(found,
            "a random level book can select the modded spell")
    end)
end

-- A typo in a modded book must identify its missing spell when a player
-- spell pool is built, instead of silently narrowing later choices.
local function missing_book_spell_fails()
    local original_get = register.get
    local missing_id = "SPELL_TEST_MISSING_BOOK_ENTRY"

    register.get = function(category, id)
        local definition = original_get(category, id)

        if category == categories.ITEMS and
            id == item_ids.BOOK_MINOR_MAGIC then
            local spells = definition.generation.spells

            spells[#spells + 1] = missing_id
        end

        return definition
    end

    local okay, failure = pcall(books.ids)

    register.get = original_get

    harness.truthy(not okay,
        "a missing spell reference must fail book selection")
    harness.truthy(tostring(failure):find(missing_id, 1, true),
        "the broken book reference names its spell")
end

-- Exercise the real registry, policies, and book generation through one
-- overlay contract rather than recreating their eligibility rules.
function test.run(ctx)
    bundled_book_set()
    frozen_book_set_is_reused()
    overlay_changes_scope_and_coverage()
    overlay_changes_character_spells(ctx)
    overlay_changes_random_books()
    missing_book_spell_fails()
end

return test
