-- The source good-god shop can force holy wrath onto any weapon, including
-- a club. Ordinary generation weights are probabilities, not legality.
local catalog = require("policy.catalog")
local brands = require("constants.weapon_brands")
local ids = require("ids.items")
local harness = require("tests.harness")
local items = require("policy.inventory.items")

local test = {}

-- Exercise the actual item validator used by generated shop stock and
-- saved items, with real weapon definitions from the effective catalog.
local function accepts(kind_id, ego)
    return pcall(items.validate, {
        kind_id = kind_id,
        quantity = 1,
        charges = 0,
        plus = 0,
        ego = ego,
    }, catalog.get("items", kind_id))
end

-- Source makeitem.cc allows universal brands beyond a base's random table,
-- while melee/ranged brands and the quick-blade speed exception stay strict.
function test.run()
    harness.truthy(accepts(ids.WPN_CLUB, brands.HOLY_WRATH),
        "authored holy club is a legal source weapon")
    harness.truthy(accepts(ids.WPN_CLUB, brands.CHAOS),
        "forced Chaos Knight brand stays legal")
    harness.truthy(accepts(ids.WPN_LONGBOW, brands.ACID),
        "acid is a ranged source brand")
    harness.falsy(accepts(ids.WPN_CLUB, brands.ACID),
        "acid cannot brand a melee club")
    harness.falsy(accepts(ids.WPN_LONGBOW, brands.ANTIMAGIC),
        "antimagic cannot brand a bow")
    harness.falsy(accepts(ids.WPN_QUICK_BLADE, brands.SPEED),
        "quick blades cannot gain speed")
    harness.falsy(accepts(ids.WPN_CLUB, brands.CONFUSE),
        "non-item sentinel brand cannot enter an item")
end

return test
