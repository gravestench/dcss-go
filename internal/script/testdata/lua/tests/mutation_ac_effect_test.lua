local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player, mutations.MUT_TOUGH_SKIN, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_RUGGED_BROWN_SCALES, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_ICY_BLUE_SCALES, 3)
    records.grant_acquired(ctx, player,
        mutations.MUT_PHYSICAL_VULNERABILITY, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.AC_PARTIAL_X100), -300,
        "partial AC includes Tough Skin and physical vulnerability")
    harness.equal(effects.full_sum(ctx, player,
        capabilities.AC_FULL_X100), 500,
        "full AC includes Rugged Brown and Icy Blue Scales")
end

return test
