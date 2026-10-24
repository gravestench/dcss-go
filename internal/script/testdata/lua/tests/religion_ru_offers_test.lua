-- Ru's three choices must be saved once, then survive later god-time checks.
-- This uses the production catalog and component schemas, not test copies.
local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local offers = require("policy.religion.ru.offers")
local species = require("ids.species")
local upkeep = require("policy.religion.upkeep")

local test = {}

-- The first god-time deadline should turn enough saved progress into three
-- distinct offers. The second deadline must not consume selection RNG.
function test.run(ctx)
    local player = ctx:create()
    local draws = 0
    local timed = setmetatable({}, { __index = ctx })

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Ru offer test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 5,
        total_xp = 100,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = 10,
        next_god_time_aut = 200,
    })
    ctx:add(player, component.RELIGION_RU, {
        sacrifice_progress = 50,
        sacrifice_delay = 50,
        sacrifice_penalty = 0,
        available = {},
        health = {},
        essence = {},
        purity = {},
        arcana = {},
    })

    -- Zero is a valid draw at every bound. The count detects accidental
    -- rerolls without depending on a particular seeded offer trio.
    function timed:random(_, _)
        draws = draws + 1

        return 0
    end

    function timed:aut()
        return 190
    end

    upkeep.tick(timed, player, 10)

    local state = ctx:get(player, component.RELIGION_RU)
    local seen = {}

    harness.equal(#state.available, 3)

    for _, id in ipairs(state.available) do
        harness.truthy(not seen[id], "Ru choices must be distinct")
        seen[id] = true
        harness.truthy(state.quoted_piety[id] > 0)
    end

    harness.truthy(draws > 1, "Ru selection uses religion RNG")

    local used = draws

    offers.at_god_time(timed, player)
    harness.equal(draws, used, "an outstanding offer does not reroll")

    -- The same saved state can become eligible again only after choices
    -- are resolved. Neither insufficient progress nor six stars rolls.
    state.available = {}
    state.quoted_piety = {}
    state.sacrifice_progress = 49
    ctx:set(player, component.RELIGION_RU, state)
    offers.at_god_time(timed, player)
    harness.equal(draws, used, "progress below delay does not roll")

    state.sacrifice_progress = 50
    ctx:set(player, component.RELIGION_RU, state)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = 160
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    offers.at_god_time(timed, player)
    harness.equal(draws, used, "six stars closes Ru offers")

    -- A mod catalog with exactly three affordable choices and one costly
    -- one checks the source cap without copying the production roster.
    local original_all = catalog.all
    local fixture = {
        {
            id = "test.ru.cheap_one",
            base_piety = 1,
            mutation_id = mutations.MUT_COWARDICE,
        },
        {
            id = "test.ru.cheap_two",
            base_piety = 10,
            mutation_id = mutations.MUT_COWARDICE,
        },
        {
            id = "test.ru.cheap_three",
            base_piety = 15,
            mutation_id = mutations.MUT_COWARDICE,
        },
        {
            id = "test.ru.expensive",
            base_piety = 100,
            mutation_id = mutations.MUT_COWARDICE,
        },
    }

    function catalog.all(category)
        if category == categories.RU_SACRIFICES then
            return fixture
        end

        return original_all(category)
    end

    offers.new(timed, player, 159)
    state = ctx:get(player, component.RELIGION_RU)
    harness.equal(#state.available, 3)

    for _, id in ipairs(state.available) do
        harness.truthy(id ~= fixture[4].id,
            "over-cap choice is excluded when three cheap offers exist")
    end

    -- A failed wizard-like pool must clear vectors from an old offer.
    fixture[3] = nil
    fixture[4] = nil
    state.health = { mutations.MUT_FRAIL }
    ctx:set(player, component.RELIGION_RU, state)
    harness.equal(offers.new(timed, player, 10), false)
    state = ctx:get(player, component.RELIGION_RU)
    harness.equal(#state.available, 0)
    harness.equal(#state.health, 0)
    catalog.all = original_all
end

return test
