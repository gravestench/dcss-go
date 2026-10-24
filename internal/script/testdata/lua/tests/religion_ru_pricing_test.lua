-- Source prices vary with the exact mutation Ru asks the player to take.
-- These examples pin observable source values, including the final blur.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.ru_sacrifices")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local pricing = require("policy.religion.ru.pricing")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- One zero draw takes the lowest value of a nonzero blur range. Frail and
-- physical vulnerability must remain differently priced.
function test.run(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local health = catalog.get(categories.RU_SACRIFICES,
        ids.HEALTH)
    local essence = catalog.get(categories.RU_SACRIFICES,
        ids.ESSENCE)
    local purity = catalog.get(categories.RU_SACRIFICES,
        ids.PURITY)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Ru pricing test",
    })

    function game:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        harness.truthy(bound > 1)

        return 0
    end

    harness.equal(pricing.quote(game, player, health,
        { mutations.MUT_FRAIL }), 32)
    harness.equal(pricing.quote(game, player, health,
        { mutations.MUT_PHYSICAL_VULNERABILITY }), 27)
    harness.equal(pricing.quote(game, player, essence,
        { mutations.MUT_WEAK_WILLED }), 32)
    harness.equal(pricing.quote(game, player, purity,
        { mutations.MUT_SCREAM }), 7)
end

return test
