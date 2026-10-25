-- Ru must inspect the full future Demonspawn schedule. An unearned Robust
-- rank still excludes Frail from a new Health sacrifice offer.
local component = require("constants.component")
local facets = require("ids.demonspawn_facets")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local variants = require("policy.religion.ru.variants")

local test = {}

-- The component uses the same schema that the schedule owner writes.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_DEMONSPAWN,
        job_id = jobs.JOB_FIGHTER,
        name = "Ru facet test",
    })

    harness.truthy(variants.valid(ctx, player, mutations.MUT_FRAIL))
    local future = ctx:create()

    ctx:add(future, component.DEMONSPAWN_TRAIT, {
        owner = player,
        facet_id = facets.DS_FACET_ROBUST,
        rank_index = 1,
        mutation_id = mutations.MUT_ROBUST,
        level = 20,
    })

    harness.falsy(variants.valid(ctx, player, mutations.MUT_FRAIL),
        "future Robust must exclude Ru Frail")
end

return test
