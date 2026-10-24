-- All static source shop specifications parse into selectable catalog entries.

local ids = require("ids.shops")
local terrain = require("constants.terrain")
local harness = require("tests.harness")
local shop_spec = require("policy.generation.vaults.shop_spec")
local catalog = require("policy.generation.vaults.catalog")
local directives = require("constants.vault_directives")
local stock_request = require("policy.shops.stock_request")
local quality = require("constants.vault_item_quality")
local armour_egos = require("constants.armour_egos")
local weapon_brands = require("constants.weapon_brands")
local missile_brands = require("constants.missile_egos")

local test = {}

local site = {
    path = "vaults/shop/hellmonk_bargain_basement.des",
    line = 5,
    vault_id = "hellmonk_bargain_basement",
}

-- A source shop line carries clearance, greed, count, and concrete stock.
local function clearance_and_fixed_stock()
    local alternatives = shop_spec.parse(
        "general shop type:Last-Chance suffix:Deals greed:0 count:7 " ..
        "use_all ; ring of fire plus:4 | wand of flame charges:1",
        site)
    local fixed = alternatives[1]

    harness.equal(#alternatives, 1, "one shop alternative")
    harness.equal(fixed.kind_id, ids.SHOP_GENERAL, "general shop ID")
    harness.equal(fixed.greed, 0, "zero greed retained")
    harness.equal(fixed.count, 7, "source count")
    harness.truthy(fixed.use_all, "use all source stock")
    harness.equal(fixed.type_name, "Last-Chance", "type name")
    harness.equal(fixed.suffix, "Deals", "suffix")
    harness.equal(fixed.items[1].plus, 4, "enchantment request")
    harness.equal(fixed.items[2].charges, 1, "charge request")
end

-- Slash-separated shop types remain weighted alternatives in parsed specs.
local function weighted_alternatives()
    local alternatives = shop_spec.parse(
        "antiques shop / antique weapon shop w:5 / " ..
        "antique armour shop w:5",
        site)

    harness.equal(#alternatives, 3, "three source alternatives")
    harness.equal(alternatives[1].kind_id, ids.SHOP_GENERAL_ANTIQUE,
        "antique shop ID")
    harness.equal(alternatives[1].weight, 10, "default weight")
    harness.equal(alternatives[2].kind_id, ids.SHOP_WEAPON_ANTIQUE,
        "antique weapon ID")
    harness.equal(alternatives[2].weight, 5, "source alternative weight")
    harness.equal(alternatives[3].kind_id, ids.SHOP_ARMOUR_ANTIQUE,
        "antique armour ID")
end

-- Bazaar source maps may replace a shop with a fountain. Keep both choices
-- in the same weighted draw so the map's authored odds still apply.
local function shop_or_fountain()
    local alternatives = shop_spec.parse("any shop / T", site)

    harness.equal(#alternatives, 2, "shop or fountain alternatives")
    harness.equal(alternatives[1].kind_id, ids.SHOP_RANDOM,
        "Bazaar shop alternative")
    harness.equal(alternatives[2].terrain_id,
        terrain.DNGN_FOUNTAIN_BLUE, "Bazaar fountain alternative")
end

-- Source shop names encode spaces as underscores; decode each name field
-- before it reaches UI text, while preserving punctuation and capitalization.
local function source_name_spacing()
    local selected = shop_spec.parse(
        "general shop name:Deep_Dragon type:CLEARANCE_SALE! " ..
        "suffix:Fine_Goods", site)[1]

    harness.equal(selected.name, "Deep Dragon", "owner underscores")
    harness.equal(selected.type_name, "CLEARANCE SALE!", "type underscores")
    harness.equal(selected.suffix, "Fine Goods", "suffix underscores")
end

-- Randart request wins when a source stock item also carries good-item flags.
local function randart_overrides_good_item()
    local selected = shop_spec.parse(
        "armour shop ; any armour good_item randart", site)[1].items[1]
    local request = stock_request.apply({}, {
        depth = 10,
        quality = quality.ORDINARY,
        site = site.path,
    }, selected, site)

    harness.equal(request.quality, quality.RANDART,
        "randart takes precedence over good_item")
end

-- DES uses short ego tokens while live items carry named class-specific IDs.
-- Resolve them before materialization so deeper shop maps cannot fail late.
local function stock_egos_use_item_ids()
    local cases = {
        {
            stock = "any armour ego:fire_resistance",
            expected = armour_egos.FIRE_RESISTANCE,
        },
        {
            stock = "any weapon ego:flaming",
            expected = weapon_brands.FLAMING,
        },
        {
            stock = "boomerang ego:silver",
            expected = missile_brands.SILVER,
        },
        {
            stock = "plate armour ego:none",
            expected = "",
        },
    }

    for _, case in ipairs(cases) do
        local selected = shop_spec.parse(
            "general shop ; " .. case.stock, site)[1].items[1]
        local request = stock_request.apply({}, {
            depth = 15,
            quality = quality.ORDINARY,
            site = site.path,
        }, selected, site)

        harness.equal(request.ego, case.expected,
            "stock ego for " .. case.stock)
    end
end

-- A malformed stock count must fail at parse time with a source path, so a
-- mod author can repair the offending DES line before generating a level.
local function rejects_unplayable_count()
    local ok, message = pcall(shop_spec.parse,
        "general shop count:21", site)

    harness.falsy(ok, "shop count above 20 accepted")
    harness.truthy(message:find(site.path, 1, true),
        "error lacks source path")
end

-- Validate every committed DES shop line, not only synthetic examples.
local function parses_all_static_source_shops()
    local count = 0

    for _, path in ipairs(mod.paths("vaults/shop", ".des")) do
        local id = path:match("/([^/]+)%.des$")
        local vault = catalog.get(id)

        for _, operation in ipairs(vault.operations) do
            if operation.kind == directives.KFEAT then
                local expression = operation.argument:match(
                    "^[^=:]+[=:]%s*(.+)$")

                if expression and shop_spec.is_shop(expression) then
                    local source_site = {
                        path = path,
                        line = operation.line,
                        vault_id = id,
                    }
                    local alternatives =
                        shop_spec.parse(expression, source_site)

                    harness.truthy(#alternatives > 0,
                        "source shop has alternatives")

                    for _, alternative in ipairs(alternatives) do
                        for _, selected in ipairs(alternative.items) do
                            stock_request.apply({}, {
                                depth = 10,
                                quality = quality.ORDINARY,
                                site = path,
                            }, selected, source_site)
                        end
                    end

                    count = count + 1
                end
            end
        end
    end

    harness.truthy(count >= 50, "all static source shops parsed")
end

-- Run synthetic grammar cases and the full committed shop corpus to catch
-- both edge-case parsing errors and drift in actual DES definitions.
function test.run()
    clearance_and_fixed_stock()
    weighted_alternatives()
    shop_or_fountain()
    source_name_spacing()
    randart_overrides_good_item()
    stock_egos_use_item_ids()
    rejects_unplayable_count()
    parses_all_static_source_shops()
end

return test
