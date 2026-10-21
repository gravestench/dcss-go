-- Source castle geometry adapts to a primary along a map edge.
local assertions = require("tests.layout_geoelf_test")

local test = {}

-- Generate the source edge/corner variant while checking primary ownership and castle masks.
function test.run()
    assertions.castle_layout({
        x1 = 1,
        x2 = 22,
        y1 = 25,
        y2 = 40,
    })
end

return test
