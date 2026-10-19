-- Gold is the fixed source kind.

local classes = require("ids.object_classes")
local harness = require("tests.harness")
local ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local requests = require("policy.generation.vaults.specs.random_items")

local test = {}

-- Source shorthand must preserve quality and depth until the generator picks a subtype.
local function descriptors_preserve_source_request()
    local ordinary = requests.describe("random_item", 2)
    local star = requests.describe("*", 2)
    local gold = requests.describe("random_gold", 2)

    harness.equal(ordinary.kind_id, classes.OBJ_RANDOM,
        "random subtype waits for item generator")
    harness.equal(ordinary.quality, quality.ORDINARY,
        "ordinary quality")
    harness.equal(star.depth, 9, "source star depth boost")
    harness.equal(star.quality, quality.STAR, "star quality")
    harness.equal(gold.kind_id, ids.OBJ_GOLD,
        "gold is the fixed source kind")
end

-- Check random, starred, and fixed-gold request descriptors together.
function test.run()
    descriptors_preserve_source_request()
end

return test
