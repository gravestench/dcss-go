local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.traps")
local held = require("policy.traps.held")

local test = {}

function test.run(ctx)
    local actor = ctx:create()

    harness.truthy(held.catch_web(ctx, actor), "first web catches actor")
    harness.equal(ctx:get(actor, component.TRAP_HELD).kind_id,
        ids.TRAP_WEB, "web state belongs to actor")
    harness.falsy(held.catch_web(ctx, actor), "web does not stack")
    harness.falsy(held.escape(ctx, actor), "first source web roll struggles")
    harness.truthy(ctx:has(actor, component.TRAP_HELD),
        "failed escape keeps held state")

    held.release(ctx, actor)
    harness.falsy(ctx:has(actor, component.TRAP_HELD),
        "forced relocation releases web restraint")
end

return test
