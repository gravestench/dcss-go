
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local harness = require("tests.harness")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")

local test = {}

-- Ordinary characters may join a god.
function test.run(ctx)
    local ordinary = ctx:create()
    local forlorn = ctx:create()

    records.grant_acquired(ctx, forlorn, mutations.MUT_FORLORN, 1)

    harness.equal(effects.sum(ctx, ordinary,
        capabilities.WORSHIP_FORBIDDEN), 0,
        "ordinary characters may join a god")
    harness.equal(effects.sum(ctx, forlorn,
        capabilities.WORSHIP_FORBIDDEN), 1,
        "Forlorn forbids god conversion")
end

return test
