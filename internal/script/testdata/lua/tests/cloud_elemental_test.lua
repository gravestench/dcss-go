local harness = require("tests.harness")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local ids = require("ids.clouds")
local elemental = require("policy.clouds.effects.elemental")

local test = {}

function test.run()
    local draws = {}
    local ctx = {}

    function ctx:random(_, size)
        draws[#draws + 1] = size
        return 0
    end

    local fire = catalog.get(categories.CLOUDS, ids.CLOUD_FIRE)
    local acid = catalog.get(categories.CLOUDS, ids.CLOUD_ACID)

    harness.equal(elemental.raw(ctx, fire, false), fire.damage.base,
        "monster cloud base uses source metadata")
    harness.equal(elemental.raw(ctx, fire, true), fire.damage.base + 4,
        "source extra player base is applied")
    harness.equal(elemental.raw(ctx, acid, true, 12),
        acid.damage.base + 4,
        "acid's extra player random span preserves its base")
    harness.truthy(#draws >= 3,
        "source average uses the named cloud RNG")
end

return test
