-- Divine powers share rank, penance, and Invocations arithmetic while
-- each god supplies its own power names and commitment costs.
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local piety = require("policy.religion.piety")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- One real worship component can change patron without copying any of
-- the catalog's god definitions into this rule test.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Divine cost tester",
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.LUGONU,
        piety = piety.breakpoint(3),
        penance = {},
    })

    harness.truthy(costs.available(ctx, player, gods.LUGONU, 3))
    harness.falsy(costs.available(ctx, player, gods.LUGONU, 4))
    harness.falsy(costs.available(ctx, player, gods.BEOGH, 1))
    harness.equal(costs.failure_chance(ctx, player, 85, 7, 20),
        85 - math.floor(piety.breakpoint(3) / 20))

    local game = setmetatable({}, { __index = ctx })

    function game:random(stream, bound)
        harness.equal(stream, streams.RELIGION)

        return bound - 1
    end

    -- Source generic_cost(10) draws 0..5; generic_cost(28) draws
    -- 0..14. The high draw catches a mistaken fixed numeric cost.
    harness.truthy(type(costs.piety_cost) == "function")
    harness.equal(costs.piety_cost(game, 10), 15)
    harness.equal(costs.piety_cost(game, 28), 42)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.LUGONU] = 1
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.falsy(costs.available(ctx, player, gods.LUGONU, 1))
end

return test
