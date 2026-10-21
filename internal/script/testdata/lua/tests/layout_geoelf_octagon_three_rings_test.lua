-- The source octagon ring-count variant retains its fixed room template and connected graph.
local assertions = require("tests.layout_geoelf_test")

local test = {}

-- Exercise this source ring count independently of the other variants' random choices.
function test.run()
    assertions.ordinary_layout("layout_geoelf_octagon", 4, 25)
end

return test
