
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Supply a two-point-per-level HP effect for additive registry composition.
function test.flat_bonus(level)
    return level * 2
end

-- Supply a conflicting three-point effect to exercise duplicate registration.
function test.conflicting_bonus(level)
    return level * 3
end

-- Existing Robust percentage survives another effect module.
function test.run(ctx)
    registry.add(mutations.MUT_ROBUST, {
        [capabilities.HP_FLAT] = test.flat_bonus,
    })

    local player = ctx:create()

    records.grant_acquired(ctx, player, mutations.MUT_ROBUST, 1)

    harness.equal(registry.sum(ctx, player, capabilities.HP_PERCENT), 10,
        "existing Robust percentage survives another effect module")
    harness.equal(registry.sum(ctx, player, capabilities.HP_FLAT), 2,
        "new effect module contributes a separate capability")

    local duplicate = pcall(registry.add, mutations.MUT_ROBUST, {
        [capabilities.HP_FLAT] = test.conflicting_bonus,
    })

    harness.falsy(duplicate, "two modules cannot own one mutation capability")
end

return test
