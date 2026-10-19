-- Forced item generation preserves source stack, brand, and request failure rules.

local purpose = require("constants.item_generation_purpose")
local streams = require("constants.rng_streams")
local generation = require("policy.item_generation")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local brands = require("constants.weapon_brands")
local catalog = require("policy.catalog")
local weapon_brands = require("policy.item_generation.weapon_brands")

local test = {}

-- Minimum draws expose source floors for stack size and plus rolls.
local function zero_context()
    local context = {
        draws = 0,
    }

    -- Count actual item draws while returning the first weighted slot, so an
    -- empty brand pool can be proven to consume no RNG.
    function context:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION, "named item RNG stream")
        harness.truthy(bound > 0, "positive draw bound")
        self.draws = self.draws + 1

        return 0
    end

    return context
end

-- Maximum legal draws exercise the upper boundary of weighted brands.
local function last_context()
    local context = {}

    -- Select the last legal slot to probe weight boundaries without changing
    -- the production generator or depending on a seed.
    function context:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION, "named item RNG stream")

        return bound - 1
    end

    return context
end

-- Compare ordinary and good Gold to expose the different source quantity paths.
local function fixed_gold_rolls_source_quantity()
    local ordinary = generation.roll(zero_context(), {
        kind_id = item_ids.OBJ_GOLD,
        depth = 5,
        quality = quality.ORDINARY,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "test gold",
    })
    local good = generation.roll(zero_context(), {
        kind_id = item_ids.OBJ_GOLD,
        depth = 5,
        quality = quality.GOOD,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "test good gold",
    })

    harness.equal(ordinary.kind_id, item_ids.OBJ_GOLD, "fixed gold kind")
    harness.equal(ordinary.quantity, 1, "ordinary gold quantity")
    harness.equal(good.quantity, 100, "good gold quantity")
    harness.equal(ordinary.plus, 0, "gold plus")
end

-- Potion stacks use the item generation RNG even when kind selection is forced.
local function fixed_potion_keeps_source_stack_rolls()
    local rolled = generation.roll(zero_context(), {
        kind_id = item_ids.POT_CURING,
        depth = 1,
        quality = quality.ORDINARY,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "test potion",
    })

    harness.equal(rolled.kind_id, item_ids.POT_CURING, "fixed potion kind")
    harness.equal(rolled.quantity, 3, "both source stack increments")
end

-- A forced kind outside the requested class reports the authored request site.
local function impossible_forced_request_reports_site()
    local okay, message = pcall(generation.roll, zero_context(), {
        class_id = "OBJ_SCROLLS",
        kind_id = item_ids.WPN_CLUB,
        depth = 1,
        quality = quality.ORDINARY,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "vaults/test.des:12",
    })

    harness.falsy(okay, "mismatched forced kind must fail")
    harness.truthy(tostring(message):find("vaults/test.des:12", 1, true),
        "error has caller site")
    harness.truthy(tostring(message):find(item_ids.WPN_CLUB, 1, true),
        "error has forced kind")
end

-- The upper legal draw chooses the final authored Dagger brand from the production table.
local function good_weapon_uses_source_brand_table()
    local rolled = generation.roll(last_context(), {
        kind_id = item_ids.WPN_DAGGER,
        depth = 8,
        quality = quality.GOOD,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "test branded dagger",
    })

    harness.equal(rolled.ego, brands.ANTIMAGIC,
        "last source dagger brand")
end

-- A Staff's catalogued mod.null pool means no ego; the branch must consume no brand draw.
local function staff_without_brands_keeps_empty_ego()
    local context = zero_context()
    local staff = catalog.get("items", item_ids.WPN_STAFF)
    local ego = weapon_brands.roll(context, staff, {
        depth = 8,
        quality = quality.GOOD,
    })

    harness.equal(ego, "", "unbranded production Staff has empty ego")
    harness.equal(context.draws, 0,
        "a missing brand pool consumes no item-generation RNG")
end

-- A failed randart request cannot silently degrade into a mundane item.
local function impossible_randart_does_not_become_ordinary()
    local okay, message = pcall(generation.roll, zero_context(), {
        kind_id = item_ids.WPN_CLUB,
        depth = 1,
        quality = quality.RANDART,
        allow_uniques = true,
        purpose = purpose.VAULT,
        site = "vaults/forced_randart.des:7",
    })

    harness.falsy(okay, "forced club randart must fail")
    harness.truthy(tostring(message):find("vaults/forced_randart.des:7", 1,
        true), "forced randart failure has caller site")
end

-- Run fixed-kind cases together so random bounds and authored catalog data stay in one regression.
function test.run()
    fixed_gold_rolls_source_quantity()
    fixed_potion_keeps_source_stack_rolls()
    impossible_forced_request_reports_site()
    good_weapon_uses_source_brand_table()
    staff_without_brands_keeps_empty_ego()
    impossible_randart_does_not_become_ordinary()
end

return test
