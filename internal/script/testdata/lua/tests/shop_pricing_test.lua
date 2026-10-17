local harness = require("tests.harness")
local catalog = require("policy.catalog")
local item_ids = require("ids.items")
local artefact_ids = require("ids.artefacts")
local artefact_kinds = require("constants.artefact_kinds")

local test = {}

local function value(pricing, id, fields, known)
    local kind = catalog.get("items", id)
    local item = {
        kind_id = id,
        quantity = fields.quantity or 1,
        plus = fields.plus or 0,
        charges = fields.charges or 0,
        ego = fields.ego or "",
    }

    return pricing.item_value(kind, item, known or {}, nil)
end

function test.run()
    local pricing = require("policy.shops.pricing")
    local known = {
        type = true,
        pluses = true,
        properties = true,
    }

    harness.equal(value(pricing, item_ids.WPN_CLUB,
        { plus = 2 }, known), 110, "known enchanted club")
    harness.equal(value(pricing, item_ids.WPN_CLUB,
        { plus = 2 }, { type = true }), 10,
        "antique club hides its enchantment")
    harness.equal(value(pricing, item_ids.ARM_BUCKLER,
        { plus = 2 }, known), 145, "known buckler")
    harness.equal(value(pricing, item_ids.POT_CURING,
        { quantity = 3 }, known), 90, "known potion stack")
    harness.equal(value(pricing, item_ids.POT_CURING,
        { quantity = 3 }, {}), 27, "unknown potion stack")
    harness.equal(value(pricing, item_ids.SCR_IDENTIFY,
        {}, known), 20, "known identify scroll")
    harness.equal(value(pricing, item_ids.SCR_IDENTIFY,
        {}, {}), 10, "unknown scroll")
    harness.equal(value(pricing, item_ids.WAND_FLAME,
        { charges = 3 }, known), 21, "wand charge value")
    harness.equal(value(pricing, item_ids.RING_PROTECTION,
        { plus = 2 }, known), 100, "variable ring value")
    harness.equal(value(pricing, item_ids.RING_PROTECTION,
        { plus = 2 }, {}), 50, "unknown ring value")
    harness.equal(value(pricing, item_ids.MI_ARROW,
        { quantity = 12 }, known), 24, "missile base price")
    harness.equal(value(pricing, item_ids.BOOK_MINOR_MAGIC,
        {}, known), 180, "book spell level value")
    harness.equal(pricing.price(12, 0), 1, "minimum shop price")
    harness.equal(pricing.price(0, 110), 1,
        "source clearance sale charges minimum one gold")
    harness.equal(pricing.price(12, 110), 132, "source greed multiplier")

    local unique = {
        kind = artefact_kinds.UNIQUE,
        unique_id = artefact_ids.UNRAND_ZONGULDROK,
        properties = {},
    }
    local sword = catalog.get("items", item_ids.WPN_DOUBLE_SWORD)
    local item = {
        kind_id = item_ids.WPN_DOUBLE_SWORD,
        quantity = 1,
        plus = 9,
        charges = 0,
        ego = "",
    }

    harness.equal(pricing.item_value(sword, item, known, unique),
        800, "known unrand uses fixed source value")
end

return test
