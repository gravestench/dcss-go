-- Scroll appearance indices represent source two-byte seeds. Identifying
-- a type should reveal the same source spelling whenever that index recurs.
local appearances = require("policy.items.appearances")
local harness = require("tests.harness")
local pools = require("constants.appearance_pools")

local test = {}

-- These names come from the pinned C++ source's own scroll-name output.
function test.run(ctx)
    harness.equal(appearances.name(ctx, pools.SCROLL, 0),
        "scroll labelled REFUMOPNEI")
    harness.equal(appearances.name(ctx, pools.SCROLL, 151),
        "scroll labelled ZIJUNKAOMIOW")
end

return test
