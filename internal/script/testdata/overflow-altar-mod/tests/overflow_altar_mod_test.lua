-- One layered DES file joins the same production catalog as embedded maps.
local catalog = require("policy.generation.altar.catalog")
local harness = require("tests.harness")

local test = {}

-- The effective VFS path is discovered on boot; no Go or Lua index lists
-- every map, so an added mod definition changes the available ID set.
function test.run()
    harness.equal(#catalog.ids(), 233,
        "one overlay map joins all committed overflow maps")
    harness.truthy(catalog.get("modded_overflow_altar"),
        "the overlay map is available by its stable NAME")
end

return test
