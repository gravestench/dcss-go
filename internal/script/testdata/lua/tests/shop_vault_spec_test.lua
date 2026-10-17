local ids = require("ids.shops")
local harness = require("tests.harness")
local shop_spec = require("policy.generation.vaults.shop_spec")
local catalog = require("policy.generation.vaults.catalog")
local directives = require("constants.vault_directives")
local stock_request = require("policy.shops.stock_request")
local quality = require("constants.vault_item_quality")

local test = {}

local site = {
    path = "vaults/shop/hellmonk_bargain_basement.des",
    line = 5,
    vault_id = "hellmonk_bargain_basement",
}

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

local function source_name_spacing()
    local selected = shop_spec.parse(
        "general shop name:Deep_Dragon type:CLEARANCE_SALE! " ..
        "suffix:Fine_Goods", site)[1]

    harness.equal(selected.name, "Deep Dragon", "owner underscores")
    harness.equal(selected.type_name, "CLEARANCE SALE!", "type underscores")
    harness.equal(selected.suffix, "Fine Goods", "suffix underscores")
end

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

local function rejects_unplayable_count()
    local ok, message = pcall(shop_spec.parse,
        "general shop count:21", site)

    harness.falsy(ok, "shop count above 20 accepted")
    harness.truthy(message:find(site.path, 1, true),
        "error lacks source path")
end

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

function test.run()
    clearance_and_fixed_stock()
    weighted_alternatives()
    source_name_spacing()
    randart_overrides_good_item()
    rejects_unplayable_count()
    parses_all_static_source_shops()
end

return test
