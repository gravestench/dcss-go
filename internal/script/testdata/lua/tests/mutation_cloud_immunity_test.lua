local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player,
        mutations.MUT_IGNITE_BLOOD, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_FLAME_CLOUD_IMMUNITY, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_FREEZING_CLOUD_IMMUNITY, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_FOUL_STENCH, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.FIRE_CLOUD_IMMUNITY), 2,
        "both source fire-cloud mutations grant immunity")
    harness.equal(effects.sum(ctx, player,
        capabilities.COLD_CLOUD_IMMUNITY), 1,
        "freezing cloud immunity is active")
    harness.equal(effects.sum(ctx, player,
        capabilities.MIASMA_IMMUNITY), 1,
        "foul stench protects against miasma")
end

return test
