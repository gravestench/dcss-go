-- Uskayaw pools actual foe damage until the player reaction. A direct
-- HURT_FOE record must not grant piety during an individual hit.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")
local kinds = require("constants.religion_conduct")
local conduct = require("policy.religion.conduct")
local uskayaw = require("policy.religion.conduct.uskayaw")

local test = {}

-- Two hits become one reaction award, then the saved accumulator clears.
function test.run(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:random(_, bound)
        harness.equal(bound, 3)

        return 0
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, { level = 1 })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.USKAYAW,
        piety = 30,
    })

    for _ = 1, 2 do
        conduct.record(observed, {
            id = kinds.HURT_FOE,
            level = 0,
            known = true,
            damage = 5,
            max_health = 10,
            experience = 100,
        })
    end

    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety, 30)
    harness.equal(ctx:get(player, component.RELIGION_USKAYAW_MOMENTUM)
        .num_hurt, 2)

    uskayaw.tick(observed, player, 10)

    harness.truthy(ctx:get(player, component.RELIGION_WORSHIP).piety > 30)
    harness.equal(ctx:get(player, component.RELIGION_USKAYAW_MOMENTUM)
        .num_hurt, 0)
end

return test
