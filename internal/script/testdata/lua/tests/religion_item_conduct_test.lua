-- Potion conduct uses the player's knowledge before the potion reveals
-- itself. A known Haste potion angers Cheibriados; an unknown one is pardoned.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")
local haste = require("policy.potions.effects.haste")

local test = {}

-- The source applies Haste first and then reports the knownness-sensitive
-- offense. Both cases use the actual saved worship component.
local function quaff(ctx, known)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:random(stream, bound)
        if stream == "religion" then
            harness.equal(bound, 200)
        else
            harness.equal(stream, "potion")
        end

        return 0
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(player, component.DURATIONS, {
        haste_aut = 0,
        might_aut = 0,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.CHEIBRIADOS,
        piety = 50,
    })

    haste.apply(observed, player, known)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if known then
        harness.truthy(worship.piety < 50)
        harness.equal(worship.penance[gods.CHEIBRIADOS], 5)
    else
        harness.equal(worship.piety, 50)
        harness.equal(worship.penance[gods.CHEIBRIADOS] or 0, 0)
    end
end

-- Knownness is an action fact, not a permanent property of the potion kind.
function test.run(ctx)
    quaff(ctx, true)
    quaff(ctx, false)
end

return test
