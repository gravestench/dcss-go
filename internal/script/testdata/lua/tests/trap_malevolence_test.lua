-- The D:2 malevolence table offers only teleport at its final boundary.

local harness = require("tests.harness")
local ids = require("ids.traps")
local malevolence = require("policy.traps.malevolence")

local test = {}

-- Compare eligible malevolent outcomes across depth and visibility gates so
-- the source table cannot offer a trap before its branch rules allow it.
function test.run()
    local first = malevolence.options(1, true)
    local second = malevolence.options(2, false)
    local deep = malevolence.options(4, true)

    harness.equal(#first, 2, "D:1 can teleport or shaft")
    harness.equal(first[1], ids.TRAP_TELEPORT, "teleport is always eligible")
    harness.equal(first[2], ids.TRAP_SHAFT, "D:1 may shaft")
    harness.equal(#second, 1, "D:2 end has only teleport")
    harness.equal(#deep, 3, "D:4 allows alarm")
    harness.equal(deep[3], ids.TRAP_ALARM, "alarm is depth gated")
end

return test
