-- Rolled manual keeps acquirement skill.

local books = require("policy.scrolls.acquirement.books")
local component = require("constants.component")
local generation = require("policy.item_generation")
local harness = require("tests.harness")
local ids = require("ids.items")
local purpose = require("constants.item_generation_purpose")
local quality = require("constants.vault_item_quality")
local skills = require("ids.skills")
local species_ids = require("ids.species")
local catalog = require("policy.catalog")

local test = {}

-- Supply species and trained skill independently so manual eligibility can be
-- checked without depending on the full player skill table.
local function context(species_id, skill_id, level, book_choice, draw)
    local state = {
        entries = {
            {
                id = skill_id,
                level = level,
            },
        },
    }
    local ctx = {}

    -- Give the picker a fixed player identity so skill comparisons do not
    -- depend on entity allocation order.
    function ctx:player()
        return "player"
    end

    -- Return only the requested training state, making the test sensitive to
    -- which skill the book picker actually considers.
    function ctx:get(_, id)
        if id == component.SKILLS then
            return state
        end

        if id == component.PLAYER then
            return {
                species_id = species_id,
            }
        end
    end

    -- Keep carried books empty so acquirement considers the supplied skill
    -- profile without duplicate-book exclusions.
    function ctx:query()
        return {}
    end

    -- Pin class and book draws at their actual bounds to test selection
    -- branches deterministically rather than by sampling seeds.
    function ctx:random(_, bound)
        if bound == 71 then
            return book_choice
        end

        return math.min(draw or 0, bound - 1)
    end

    return ctx
end

-- A selected manual keeps the skill that acquirement offered after the roll.
local function manual_uses_acquirement_skill()
    local ctx = context(species_ids.SP_HUMAN, skills.SK_FIGHTING, 5, 0)
    local kind_id, extra = books.pick(ctx, ctx:player(), 1)

    harness.equal(kind_id, ids.BOOK_MANUAL, "trained fighter gets manual")
    harness.truthy(skills[extra.manual_skill_id],
        "manual skill comes from registered skill IDs")

    local rolled = generation.roll(ctx, {
        kind_id = kind_id,
        manual_skill_id = extra.manual_skill_id,
        depth = 1,
        quality = quality.GOOD,
        allow_uniques = false,
        purpose = purpose.ACQUIREMENT,
        site = "test manual acquirement",
    })

    harness.equal(rolled.components[component.ITEM_MANUAL].skill_id,
        extra.manual_skill_id, "rolled manual keeps acquirement skill")
end

-- A high Spellcasting skill should influence the level-book path; this case
-- fixes the skill values and checks the resulting picked book data.
local function level_book_uses_spellcasting()
    local ctx = context(species_ids.SP_HUMAN,
        skills.SK_SPELLCASTING, 27, 30)
    local kind_id, extra = books.pick(ctx, ctx:player(), 1)

    harness.equal(kind_id, ids.BOOK_RANDART_LEVEL,
        "acquirement selected level book")
    harness.equal(extra.acquirement_level, 9,
        "book level follows source spellcasting rule")
end

-- Felid restrictions must filter the manual pool before its RNG draw.
local function manuals_only_offer_trainable_skills()
    local species = catalog.get("species", species_ids.SP_FELID)

    for draw = 0, 200 do
        local ctx = context(species_ids.SP_FELID,
            skills.SK_AXES, 5, 0, draw)
        local kind_id, extra = books.pick(ctx, ctx:player(), 1)

        harness.equal(kind_id, ids.BOOK_MANUAL,
            "trained felid gets manual")
        harness.truthy(species.aptitudes[extra.manual_skill_id].allowed,
            "manual only offers a trainable skill")
    end
end

-- Exercise manual and level-book choices together because both use the same
-- acquirement skill profile but apply different eligibility rules.
function test.run()
    manual_uses_acquirement_skill()
    level_book_uses_spellcasting()
    manuals_only_offer_trainable_skills()
end

return test
