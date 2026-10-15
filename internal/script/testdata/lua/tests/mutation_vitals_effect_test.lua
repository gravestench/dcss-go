local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player, mutations.MUT_ROBUST, 2)
    records.grant_acquired(ctx, player, mutations.MUT_FLAT_HP, 1)
    records.grant_acquired(ctx, player, mutations.MUT_LOW_MAGIC, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_RUGGED_BROWN_SCALES, 2)

    harness.equal(effects.sum(ctx, player, capabilities.HP_PERCENT), 25,
        "Robust and Rugged Brown Scales follow source HP percentages")
    harness.equal(effects.sum(ctx, player, capabilities.HP_FLAT), 4,
        "Flat HP adds four points")
    harness.equal(effects.sum(ctx, player, capabilities.MP_PERCENT), -10,
        "Low Magic reduces maximum MP by ten percent")
end

return test
