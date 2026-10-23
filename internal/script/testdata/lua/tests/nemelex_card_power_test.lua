-- Card strength depends on the current worshipper, not the deck or file
-- that supplied the card. The same formula is used by every effect module.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local power = require("policy.religion.cards.power")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Zero Invocations exposes the integer arithmetic independently of skill
-- scaling; punishment instead uses experience level and ignores piety.
function test.run(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    function game:player()
        return player
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Card power tester",
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NEMELEX_XOBEH,
        piety = 200,
    })

    harness.equal(power.value(game, player, false), 485)
    harness.equal(power.value(game, player, true), 180)

    local draws = {
        {
            bound = 900,
            value = 0,
        },
        {
            bound = 2700,
            value = 2699,
        },
    }
    local index = 0

    function game:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        index = index + 1
        harness.equal(bound, draws[index].bound)

        return draws[index].value
    end

    harness.equal(power.level(game, 485), 1)
    harness.equal(index, 2)

    -- The first threshold is certain at 900. Only the second threshold
    -- may advance the stream, and both skip the draw above 2700.
    draws = {
        {
            bound = 2700,
            value = 2699,
        },
    }
    index = 0

    harness.equal(power.level(game, 900), 1)
    harness.equal(index, 1)
    harness.equal(power.level(game, 2700), 2)
    harness.equal(index, 1)
    harness.equal(power.level(game, 0), 0)
    harness.equal(index, 1)
end

return test
