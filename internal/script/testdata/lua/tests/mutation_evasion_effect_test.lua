
local capabilities = require("constants.mutation_capabilities")
local classes = require("constants.mutation_classes")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Removing Slow Reflexes immediately restores EV.
function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player,
        mutations.MUT_GELATINOUS_BODY, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_DISTORTION_FIELD, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_SLOW_REFLEXES, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.EVASION_BONUS), 0,
        "source EV changes are 2 plus 3 minus 5")

    records.delete(ctx, player,
        mutations.MUT_SLOW_REFLEXES, classes.ACQUIRED, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.EVASION_BONUS), 5,
        "removing Slow Reflexes immediately restores EV")
end

return test
