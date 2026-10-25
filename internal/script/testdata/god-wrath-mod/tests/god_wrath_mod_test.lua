-- One sparse mod supplies a god, its alignment, and its effect module.
-- Timed wrath and the Wrath card must both use the effective catalog.
local alignments = require("policy.religion.alignments")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local retribution = require("policy.religion.wrath.retribution")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local sources = require("constants.religion_sources")
local worship = require("policy.religion.worship")

local test = {}
local mod_god = "GOD_TEST_WROUGHT"

-- The added god is good and hates a source evil god through definition
-- flags. No shared Lua registry or source ID file was edited for this test.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.MAKHLEB,
        piety = 15,
        penance = {
            [mod_god] = 8,
        },
    })

    harness.truthy(alignments.good(mod_god))
    harness.truthy(alignments.evil(gods.MAKHLEB))
    harness.truthy(alignments.hates(mod_god, gods.MAKHLEB))

    local active = retribution.active_gods(ctx, player)

    harness.equal(#active, 1)
    harness.equal(active[1], mod_god)

    local draw = setmetatable({}, { __index = ctx })
    local first = true

    function draw:random(stream, bound)
        if first then
            first = false
            harness.equal(stream, streams.CARDS)
            harness.equal(bound, 27)

            return 26
        end

        return ctx:random(stream, bound)
    end

    harness.equal(retribution.sample(draw, player), mod_god)
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_timeout, 17)

    local converting = ctx:create()

    ctx:add(converting, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(converting, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(converting, component.RELIGION_WORSHIP, {
        penance = {
            [mod_god] = 8,
        },
    })

    worship.join(ctx, converting, gods.MAKHLEB, sources.ALTAR)

    harness.truthy(ctx:get(converting, component.RELIGION_WORSHIP)
        .wrath_xp_remaining > 0,
        "a modded good god did not start its conversion timer")
end

return test
