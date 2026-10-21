-- The source octagon room graph runs through the actual production GeoElf family.
local assertions = require("tests.layout_geoelf_test")

local test = {}

-- Keep each full source rendering in its own bounded production-VM test.
function test.run()
    assertions.ordinary_layout("layout_geoelf_octagon", 47)
end

return test
