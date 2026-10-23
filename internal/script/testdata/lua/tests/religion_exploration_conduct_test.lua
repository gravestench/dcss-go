-- Exploration conduct runs through the same policy the Go view owner calls
-- for newly seen cells. The fixture imports live content and worship schema.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")
local exploration = require("policy.world.exploration")

local test = {}

-- The deterministic draw proves the source 14/2500 pulse rather than a
-- guaranteed per-cell gain or a result changed by file discovery order.
function test.run(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })
    local draws = 0

    function observed:player()
        return player
    end

    function observed:random(stream, bound)
        harness.equal(stream, "religion")
        harness.equal(bound, 2500)
        draws = draws + 1

        return 0
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Explorer",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NEMELEX_XOBEH,
        piety = 15,
    })

    exploration.run(observed, {
        count = 1,
        width = 1,
        height = 1,
        origins = {},
        difficulty = {},
    })

    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety, 16)
    harness.equal(draws, 1)
end

return test
