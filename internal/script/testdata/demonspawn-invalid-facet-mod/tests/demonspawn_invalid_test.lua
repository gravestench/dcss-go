-- An invalid layered facet should fail at character creation, before a
-- character has a partial or impossible ancestry schedule to save.
local component = require("constants.component")
local demonspawn = require("policy.character.demonspawn")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")

local test = {}

-- Exercise the production catalog validator through the actual start path.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_DEMONSPAWN,
        job_id = jobs.JOB_FIGHTER,
        name = "Invalid facet test",
    })

    local accepted, reason = pcall(demonspawn.start, ctx, player)

    harness.falsy(accepted,
        "over-cap facet passed catalog validation")
    harness.truthy(string.find(tostring(reason), "mutation cap", 1, true),
        "facet failed for another reason: " .. tostring(reason))
    harness.equal(#demonspawn.list(ctx, player), 0)
end

return test
