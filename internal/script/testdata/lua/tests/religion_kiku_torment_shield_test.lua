-- Kiku's four-star passive protects against ordinary Torment, but source
-- pain branding temporarily suppresses that shield with gift_timeout.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local resistance = require("policy.combat.player_resistance")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local torment_sources = require("constants.torment_sources")

local test = {}

-- Force the full-shield draw to succeed if Kiku protection is active.
-- A blessing-source call must skip that draw and retain ordinary HP loss.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Shield tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.KIKUBAAQUDGHA,
        piety = 200,
    })

    local proxy = setmetatable({}, { __index = ctx })
    local draws = 0

    function proxy:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        harness.truthy(bound > 0)
        draws = draws + 1

        return 0
    end

    harness.equal(resistance.torment_loss(proxy, player, 100), 0)
    harness.equal(draws, 1)
    harness.equal(resistance.torment_loss(proxy, player, 100,
        torment_sources.KIKU_BLESSING), 49)
    harness.equal(draws, 1,
        "pain branding must not roll Kiku's protection")
end

return test
