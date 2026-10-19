-- All ten active source shops have stock policies; removed shop IDs stay
-- inaccessible, and materialized stock belongs only to its shop.

local harness = require("tests.harness")
local categories = require("constants.catalog")
local content = require("policy.catalog")
local components = require("constants.component")
local item_ids = require("ids.items")
local shop_ids = require("ids.shops")
local materialize = require("policy.item_generation.materialize")

local test = {}

local active = {
    shop_ids.SHOP_WEAPON,
    shop_ids.SHOP_ARMOUR,
    shop_ids.SHOP_WEAPON_ANTIQUE,
    shop_ids.SHOP_ARMOUR_ANTIQUE,
    shop_ids.SHOP_GENERAL_ANTIQUE,
    shop_ids.SHOP_JEWELLERY,
    shop_ids.SHOP_BOOK,
    shop_ids.SHOP_DISTILLERY,
    shop_ids.SHOP_SCROLL,
    shop_ids.SHOP_GENERAL,
}

-- Compare runtime shop definitions with the active source catalog so mod
-- discovery cannot silently drop a shop kind before generation uses it.
function test.run(ctx)
    local catalog = require("policy.shops.catalog")
    local definitions = content.all(categories.SHOPS)

    harness.equal(#definitions, #active, "active source shop count")

    local expected = {}
    local seen = {}

    for _, id in ipairs(active) do
        expected[id] = true
    end

    -- Check membership separately from the catalog's stable ID traversal.
    local previous_id

    for _, definition in ipairs(definitions) do
        harness.truthy(expected[definition.id],
            "unexpected active shop " .. definition.id)
        harness.falsy(seen[definition.id],
            "duplicate active shop " .. definition.id)
        if previous_id then
            harness.truthy(previous_id < definition.id,
                "shop catalog IDs are ascending")
        end
        seen[definition.id] = true
        previous_id = definition.id
        harness.truthy(definition.name ~= "", "source shop name")
        harness.truthy(type(definition.identifies_stock) == "boolean",
            "identification policy")
        harness.truthy(type(definition.class_weights) == "table",
            "stock class policy")
        catalog.definition(definition)
    end

    for _, id in ipairs(active) do
        harness.truthy(seen[id], "missing active shop " .. id)
    end

    for _, id in ipairs({ shop_ids.SHOP_EVOKABLES, shop_ids.SHOP_FOOD }) do
        local okay = pcall(content.get, categories.SHOPS, id)

        harness.falsy(okay, "removed source shop is not active")
    end

    local bad = {
        id = "SHOP_TEST",
        name = "Test",
        identifies_stock = true,
        generation_weight = 1,
        class_weights = {},
    }
    local okay = pcall(catalog.definition, bad)

    harness.falsy(okay, "empty stock class weights rejected")

    local shop = ctx:create()
    local stock = materialize.create(ctx, {
        kind_id = item_ids.WPN_CLUB,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    }, {
        shop = shop,
        order = 1,
    })

    harness.truthy(ctx:has(stock, components.SHOP_STOCK),
        "generated stock has one owner")
    harness.falsy(ctx:has(stock, components.POSITION),
        "stock has no floor location")
    harness.falsy(ctx:has(stock, components.CARRIED_BY),
        "stock has no carrier")
end

return test
