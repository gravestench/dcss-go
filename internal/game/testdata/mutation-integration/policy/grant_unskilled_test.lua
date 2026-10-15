local classes = require("constants.mutation_classes")
local mutations = require("ids.mutations")
local transition = require("policy.mutations.transition")

local test = {}

function test.grant(ctx)
    return transition.grant(ctx, ctx:player(),
        mutations.MUT_UNSKILLED, classes.ACQUIRED, true)
end

register.policy({
    id = "test.grant_unskilled",
    run = test.grant,
})

return test
