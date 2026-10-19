-- Cloak uses source ego table.

local purpose = require("constants.item_generation_purpose")
local streams = require("constants.rng_streams")
local armour_egos = require("constants.armour_egos")
local brands = require("constants.missile_brands")
local generation = require("policy.item_generation")
local harness = require("tests.harness")
local ids = require("ids.items")
local quality = require("constants.vault_item_quality")

local test = {}

-- Select the first or last eligible weight slot to exercise subtype edge
-- cases without depending on a random seed.
local function context(last)
    local ctx = {}

    -- Assert subtype rolls use the item stream and a nonempty range before
    -- returning the boundary draw requested by the case.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION, "item source RNG stream")
        harness.truthy(bound > 0, "positive source draw bound")

        return last and bound - 1 or 0
    end

    return ctx
end

-- Supply the shared generation fields so each case changes only item kind
-- and quality, keeping ego differences attributable to subtype rules.
local function request(kind_id, quality_id)
    return {
        kind_id = kind_id,
        depth = 1,
        quality = quality_id,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "armour and missiles source test",
    }
end

-- Compare cloak and scarf ego results at the same shallow depth, where their
-- allowed subtype pools differ despite both being armour.
local function armour_subtype_egos()
    local cloak = generation.roll(context(false),
        request(ids.ARM_CLOAK, quality.GOOD))
    local scarf = generation.roll(context(false),
        request(ids.ARM_SCARF, quality.ORDINARY))

    harness.equal(cloak.ego, armour_egos.POISON_RESISTANCE,
        "cloak uses source ego table")
    harness.equal(scarf.ego, armour_egos.RESISTANCE,
        "scarf always receives source ego")
    harness.equal(scarf.plus, 0, "scarf is unenchantable")
end

-- Probe both dart brand-pool boundaries so curare and poison are selected by
-- the authored weights rather than a generic missile default.
local function missile_subtype_brands()
    local curare = generation.roll(context(false),
        request(ids.MI_DART, quality.ORDINARY))
    local poisoned = generation.roll(context(true),
        request(ids.MI_DART, quality.ORDINARY))

    harness.equal(curare.ego, brands.CURARE,
        "early dart can roll curare")
    harness.equal(poisoned.ego, brands.POISONED,
        "dart weighted tail is poisoned")
    harness.equal(curare.quantity, 2, "minimum dart stack")
    harness.equal(poisoned.quantity, 6, "maximum dart stack")
end

-- Run armour and missile subtype checks together because both depend on
-- specialized item-generation tables selected from a common request.
function test.run()
    armour_subtype_egos()
    missile_subtype_brands()
end

return test
