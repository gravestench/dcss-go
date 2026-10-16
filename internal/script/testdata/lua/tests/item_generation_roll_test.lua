local purpose = require("constants.item_generation_purpose")
local streams = require("constants.rng_streams")
local generation = require("policy.item_generation")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local brands = require("constants.weapon_brands")

local test = {}

local function zero_context()
    local context = {
        draws = 0,
    }

    function context:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION, "named item RNG stream")
        harness.truthy(bound > 0, "positive draw bound")
        self.draws = self.draws + 1

        return 0
    end

    return context
end

local function last_context()
    local context = {}

    function context:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION, "named item RNG stream")

        return bound - 1
    end

    return context
end

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

function test.run()
    fixed_gold_rolls_source_quantity()
    fixed_potion_keeps_source_stack_rolls()
    impossible_forced_request_reports_site()
    good_weapon_uses_source_brand_table()
    impossible_randart_does_not_become_ordinary()
end

return test
