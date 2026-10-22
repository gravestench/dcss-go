-- Wanderer gifts use the saved item-set picks and a separate creation
-- stream. These tests call the production gift and spell modules directly.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gifts = require("policy.character.wanderer_gifts")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local item_sets = require("constants.item_sets")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local mutation_records = require("policy.mutations.records")
local skills = require("ids.skills")
local spell_ids = require("ids.spells")
local species_ids = require("ids.species")
local spell_gifts = require("policy.character.wanderer_spells")
local streams = require("constants.rng_streams")
local wanderer_ids = require("constants.wanderer")

local test = {}

-- Reuse actual component schemas while scripting only the random draws
-- needed to distinguish source decisions from extra subgroup rerolls.
local function player_context(ctx, draws, species_id)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local index = 0

    ctx:add(player, component.PLAYER, {
        species_id = species_id or species_ids.SP_HUMAN,
        job_id = jobs.JOB_WANDERER,
    })
    ctx:add(player, component.PLAYER_ITEM_SETS, {
        choices = {
            [item_sets.HEX_WANDS] = item_ids.WAND_PARALYSIS,
            [item_sets.BEAM_WANDS] = item_ids.WAND_QUICKSILVER,
            [item_sets.BLAST_WANDS] = item_ids.WAND_ROOTS,
            [item_sets.CONCEALMENT_SCROLLS] =
                item_ids.SCR_BUTTERFLIES,
        },
    })

    function game:player()
        return player
    end

    function game:random(stream, bound)
        index = index + 1
        local expected = draws[index]

        harness.truthy(expected, "Wanderer made an extra draw")
        harness.equal(stream, streams.WANDERER,
            "Wanderer decisions use their isolated stream")
        harness.equal(bound, expected.bound,
            "Wanderer source choice bound")

        return expected.value
    end

    function game:draw_count()
        return index
    end

    return game, player
end

-- Source strong evokers draw one wand-set slot, not fresh members of all
-- three sets before selecting the actual gift.
local function strong_wands_reuse_saved_sets(ctx)
    local species = catalog.get(categories.SPECIES,
        species_ids.SP_HUMAN)
    local hex, player = player_context(ctx, {
        {
            bound = 3,
            value = 1,
        },

        {
            bound = 6,
            value = 0,
        },

        {
            bound = 16,
            value = 0,
        },

        {
            bound = 17,
            value = 0,
        },

        {
            bound = 17,
            value = 0,
        },
    })
    local grants = {}

    gifts.good(hex, species, skills.SK_EVOCATIONS, grants, {})

    harness.equal(#grants, 1)
    harness.equal(grants[1].kind_id, item_ids.WAND_PARALYSIS)
    harness.equal(hex:draw_count(), 5,
        "strong hex wand spends three source charge draws")
    harness.equal(require("policy.item_generation.item_sets")
        .choice(ctx, player, item_sets.HEX_WANDS),
        item_ids.WAND_PARALYSIS)

    local beam = player_context(ctx, {
        {
            bound = 3,
            value = 1,
        },

        {
            bound = 6,
            value = 5,
        },

        {
            bound = 3,
            value = 0,
        },
    })
    local beam_grants = {}

    gifts.good(beam, species, skills.SK_EVOCATIONS,
        beam_grants, {})

    harness.equal(beam_grants[1].kind_id,
        item_ids.WAND_QUICKSILVER)
    harness.equal(beam:draw_count(), 3,
        "strong beam wand spends one source charge draw")
end

-- Fighting upgrades the first weapon that starting gear would actually
-- equip. Felid cannot wield a prior dagger, so receives a consumable.
local function fighting_uses_equipped_weapon(ctx)
    local human = catalog.get(categories.SPECIES,
        species_ids.SP_HUMAN)
    local human_game = player_context(ctx, {})
    local human_grants = {
        {
            kind_id = item_ids.WPN_DAGGER,
            plus = 0,
        },

        {
            kind_id = item_ids.WPN_MACE,
            plus = 0,
        },
    }

    gifts.decent(human_game, human, skills.SK_FIGHTING,
        human_grants, {})

    harness.equal(human_grants[1].plus, 1,
        "Fighting upgrades the equipped weapon")
    harness.equal(human_grants[2].plus, 0,
        "Fighting leaves later carried weapons alone")

    local felid = catalog.get(categories.SPECIES,
        species_ids.SP_FELID)
    local felid_game, felid_player = player_context(ctx, {
        {
            bound = 32,
            value = 0,
        },
    }, species_ids.SP_FELID)
    local felid_grants = {
        {
            kind_id = item_ids.WPN_DAGGER,
            plus = 0,
        },
    }

    mutation_records.grant_innate(ctx, felid_player,
        mutations.MUT_NO_GRASPING, 1)

    gifts.decent(felid_game, felid, skills.SK_FIGHTING,
        felid_grants, {})

    harness.equal(felid_grants[1].plus, 0,
        "unusable weapon cannot receive the Fighting bonus")
    harness.equal(#felid_grants, 2,
        "a weaponless Felid receives the fallback consumable")
end

-- A decent tactical gift must read the stored concealment scroll without
-- choosing Fog or Butterflies again on the Wanderer stream.
local function concealment_reuses_saved_choice(ctx)
    local species = catalog.get(categories.SPECIES,
        species_ids.SP_HUMAN)
    local game = player_context(ctx, {
        {
            bound = 32,
            value = 6,
        },
    })
    local grants = {}

    gifts.decent(game, species,
        wanderer_ids.NO_GIFT_SKILL, grants, {})

    harness.equal(#grants, 1)
    harness.equal(grants[1].kind_id,
        item_ids.SCR_BUTTERFLIES)
    harness.equal(game:draw_count(), 1)
end

-- The source's exact-total filter gives eligible 2+2 books a route into
-- the result, rather than always trying 1+3 before them.
local function minor_books_choose_both_level_patterns(ctx)
    local species = catalog.get(categories.SPECIES,
        species_ids.SP_HUMAN)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local found_two_two = false

    ctx:add(player, component.PLAYER, {
        species_id = species_ids.SP_HUMAN,
        job_id = jobs.JOB_WANDERER,
    })

    function game:player()
        return player
    end

    for chosen = 0, 99 do
        local draw = 0

        function game:random(stream, bound)
            harness.equal(stream, streams.WANDERER,
                "minor books use the Wanderer stream")
            draw = draw + 1

            return (chosen + draw - 1) % bound
        end

        local pair = spell_gifts.gift(game, species,
            skills.SK_CONJURATIONS, false)

        harness.equal(#pair, 2,
            "the source minor gift contains two spells")
        harness.falsy(pair[1] == pair[2],
            "minor spellbook cannot repeat a spell")

        local first = catalog.get(categories.SPELLS, pair[1])
        local second = catalog.get(categories.SPELLS, pair[2])

        harness.equal(first.level + second.level, 4,
            "minor spell levels total four")

        if first.level == 2 and second.level == 2 then
            found_two_two = true
        end
    end

    harness.truthy(found_two_two,
        "the eligible 2+2 minor-book path must be reachable")
end

-- Source Djinni role conversion happens before the good magic gift and
-- writes the converted role back for later skill allocation.
local function djinni_spellcasting_converts_before_gift(ctx)
    local species = catalog.get(categories.SPECIES,
        species_ids.SP_DJINNI)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local draws = 0

    ctx:add(player, component.PLAYER, {
        species_id = species_ids.SP_DJINNI,
        job_id = jobs.JOB_WANDERER,
    })
    mutation_records.grant_innate(ctx, player,
        mutations.MUT_INNATE_CASTER, 1)

    function game:player()
        return player
    end

    function game:random(stream, bound)
        harness.equal(stream, streams.WANDERER)
        draws = draws + 1

        if draws == 1 then
            harness.equal(bound, 12,
                "Djinni conversion includes Spellcasting and schools")

            return 1
        end

        return 0
    end

    local actual = gifts.good(game, species,
        skills.SK_SPELLCASTING, {}, {})

    harness.equal(actual, skills.SK_CONJURATIONS,
        "Djinni gift uses the converted school")
end

-- Large bodies cannot wear ordinary mail, so strong Armour asks for the
-- source's acid dragon fallback before gear assignment changes its slot.
local function armour_fallback_for_large_species(ctx)
    local species = catalog.get(categories.SPECIES,
        species_ids.SP_TROLL)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local grants = {}

    ctx:add(player, component.PLAYER, {
        species_id = species_ids.SP_TROLL,
        job_id = jobs.JOB_WANDERER,
    })

    function game:player()
        return player
    end

    function game:random(stream, bound)
        harness.equal(stream, streams.WANDERER)
        harness.equal(bound, 2)

        return 0
    end

    gifts.good(game, species, skills.SK_ARMOUR, grants, {})

    harness.equal(grants[1].kind_id,
        item_ids.ARM_ACID_DRAGON_ARMOUR)
    harness.equal(grants[1].plus, 0)
end

-- The source's reservoir visits Hat first, then requests Helmet as the
-- actual gift. Starting gear later maps it back to Hat when anatomy needs.
local function auxiliary_hat_requests_helmet(ctx)
    local species = catalog.get(categories.SPECIES,
        species_ids.SP_HUMAN)
    local game = player_context(ctx, {
        {
            bound = 1,
            value = 0,
        },

        {
            bound = 2,
            value = 1,
        },

        {
            bound = 3,
            value = 2,
        },

        {
            bound = 4,
            value = 3,
        },
    })
    local grants = {}

    gifts.decent(game, species, skills.SK_STEALTH, grants, {})

    harness.equal(#grants, 1)
    harness.equal(grants[1].kind_id, item_ids.ARM_HELMET)
end

-- Mod-added player spells may omit a pinned source numeric ID. They must
-- remain usable without making the source-ordered candidate sort crash.
local function mod_spell_without_source_number(ctx)
    local species = catalog.get(categories.SPECIES,
        species_ids.SP_HUMAN)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local original_get = register.get

    ctx:add(player, component.PLAYER, {
        species_id = species_ids.SP_HUMAN,
        job_id = jobs.JOB_WANDERER,
    })

    function game:player()
        return player
    end

    function game:random(stream)
        harness.equal(stream, streams.WANDERER)

        return 0
    end

    -- Registry reads return copies. Intercept one definition as though a
    -- layered mod supplied it without a pinned C++ spell enum value.
    register.get = function(category, id)
        local definition = original_get(category, id)

        if category == categories.SPELLS and
            id == spell_ids.SPELL_MAGIC_DART then
            definition.numeric_id = nil
        end

        return definition
    end

    local accepted = pcall(spell_gifts.gift, game, species,
        skills.SK_CONJURATIONS, true)

    register.get = original_get

    harness.truthy(accepted,
        "a mod spell without source ordinal must still sort")
end

-- A layered mod can add a spell to a fixed player book. Wanderer must
-- inspect the effective book catalog, not a frozen list from source data.
local function mod_book_spell_is_eligible(ctx)
    local species = catalog.get(categories.SPECIES,
        species_ids.SP_HUMAN)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local original_get = register.get
    local original_ids = register.ids
    local mod_spell_id = "SPELL_TEST_WANDERER_ADDON"

    ctx:add(player, component.PLAYER, {
        species_id = species_ids.SP_HUMAN,
        job_id = jobs.JOB_WANDERER,
    })

    function game:player()
        return player
    end

    function game:random(stream)
        harness.equal(stream, streams.WANDERER)

        return 0
    end

    -- Use the production definitions as fixtures so new required spell or
    -- book fields do not drift into a second test-only schema.
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
            id == item_ids.BOOK_MINOR_MAGIC then
            local spells = definition.generation.spells

            spells[#spells + 1] = mod_spell_id
        end

        return definition
    end

    local okay, chosen = pcall(spell_gifts.gift, game, species,
        skills.SK_CONJURATIONS, true)

    register.get = original_get
    register.ids = original_ids

    harness.truthy(okay, chosen)
    harness.equal(chosen[1], mod_spell_id,
        "a spell added to a player book reaches Wanderer")
end

-- Run each branch with the same production catalogs and component fields
-- that character creation and save/restore consume.
function test.run(ctx)
    strong_wands_reuse_saved_sets(ctx)
    fighting_uses_equipped_weapon(ctx)
    concealment_reuses_saved_choice(ctx)
    minor_books_choose_both_level_patterns(ctx)
    djinni_spellcasting_converts_before_gift(ctx)
    armour_fallback_for_large_species(ctx)
    auxiliary_hat_requests_helmet(ctx)
    mod_spell_without_source_number(ctx)
    mod_book_spell_is_eligible(ctx)
end

return test
