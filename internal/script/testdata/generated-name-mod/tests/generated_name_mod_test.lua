-- The same relative-path override must affect scroll appearance naming
-- without copying the base item catalog or editing Go registration.
local appearances = require("policy.items.appearances")
local harness = require("tests.harness")
local pools = require("constants.appearance_pools")

local test = {}

-- Read the effective production caller, which imports the layered policy.
function test.run(ctx)
    harness.equal(appearances.name(ctx, pools.SCROLL, 0),
        "scroll labelled MODDED LABEL")
end

return test
