local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")

local test = {}

function test.run()
    local definitions = catalog.all(categories.JOBS)

    harness.equal(#definitions, 31, "pinned job definitions")

    for _, job in ipairs(definitions) do
        harness.truthy(job.starting_grants ~= nil,
            job.id .. " owns its starting grants")

        if job.id ~= jobs.JOB_WANDERER then
            harness.equal(type(job.starting_grants), "table",
                job.id .. " has a fixed grant list")
        end
    end

    local fighter = catalog.get(categories.JOBS, jobs.JOB_FIGHTER)

    harness.equal(#fighter.starting_grants, 3,
        "Fighter has three fixed source grants")
    harness.equal(fighter.starting_grants[1].kind_id,
        items.ARM_SCALE_MAIL, "Fighter armour")
    harness.equal(fighter.starting_grants[2].kind_id,
        items.ARM_BUCKLER, "Fighter shield")
    harness.equal(fighter.starting_grants[3].kind_id,
        items.POT_MIGHT, "Fighter potion")

    local wanderer = catalog.get(categories.JOBS, jobs.JOB_WANDERER)

    harness.equal(wanderer.starting_grants, mod.null,
        "Wanderer has generated rather than fixed gear")
end

return test
