-- The game integration fixture grants Unskilled through the real mutation transition policy.

local classes = require("constants.mutation_classes")
local mutations = require("ids.mutations")
local transition = require("policy.mutations.transition")

local test = {}

-- Grant through the normal transition path so dependent skill rules see the
-- acquired mutation, including its record and follow-up signals.
-- Example: runtime.Policy("test.grant_unskilled", nil).
function test.grant(ctx)
    return transition.grant(ctx, ctx:player(),
        mutations.MUT_UNSKILLED, classes.ACQUIRED, true)
end

register.policy({
    id = "test.grant_unskilled",
    run = test.grant,
})

return test
