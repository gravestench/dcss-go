-- Source map fixup turns maps without ORIENT into floating minivaults.
local catalog = require("policy.generation.vaults.catalog")
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local ids = require("ids.vaults")

local test = {}

-- An ordinary shop or serial child without ORIENT joins the minivault
-- pool, while an explicitly east-oriented shore remains a regular map.
local function source_orientation_controls_minivault_tag()
    harness.truthy(catalog.get(ids.shop).tags.minivault,
        "unoriented shop is a source minivault")
    harness.truthy(catalog.get(ids.chequers_serial_rivers_micro_a).tags.minivault,
        "unoriented stream is a source minivault")
    harness.falsy(catalog.get(ids.serial_bayou_shore_a).tags.minivault,
        "east-oriented shore is not a minivault")
end

-- The distinction comes from the declaration, not the resulting float
-- orientation: an explicit ORIENT float remains a regular vault.
local function explicit_float_stays_regular()
    local definition = des.parse("vaults/test/explicit_float.des", [[
NAME: explicit_float
ORIENT: float
DEPTH: D
MAP
@..
...
ENDMAP
]])

    harness.equal(definition.orientation, "float",
        "explicit float still uses floating geometry")
    harness.falsy(definition.tags.minivault,
        "explicit float does not join minivault pool")
end

-- Both real source maps and a synthetic explicit-float declaration must
-- agree on the ORIENT rule before weighted selection can use the tag.
function test.run()
    source_orientation_controls_minivault_tag()
    explicit_float_stays_regular()
end

return test
