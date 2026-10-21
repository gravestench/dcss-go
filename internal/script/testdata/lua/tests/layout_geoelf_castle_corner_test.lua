-- Source castle geometry adapts to a primary along a map corner.
local assertions = require("tests.layout_geoelf_test")

local test = {}

-- Generate the source edge/corner variant while checking primary ownership and castle masks.
function test.run()
    assertions.castle_layout({
        x1 = 1,
        x2 = 22,
        y1 = 1,
        y2 = 18,
    })
end

return test
