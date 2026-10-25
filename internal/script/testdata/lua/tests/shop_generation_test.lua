-- Authored stock uses source item weights.

local harness = require("tests.harness")
local component = require("constants.component")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local item_ids = require("ids.items")
local item_sets = require("policy.item_generation.item_sets")
local shop_ids = require("ids.shops")
local terrain = require("constants.terrain")
local shop_spec = require("policy.generation.vaults.shop_spec")
local name_modes = require("constants.name_modes")
local names = require("policy.names.source")

local test = {}

-- The grid proxy records shop entrance terrain while stock uses real ECS
-- entities and holder relations.
local function grid_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })
    local cells = {}

    -- Permit positive test coordinates while still exercising the production
    -- placement check through the same context method.
    function proxy:walkable(_, x, y)
        return x > 0 and y > 0
    end

    -- Return recorded entrance terrain and default untouched cells to floor,
    -- making a small grid sufficient for a shop placement test.
    function proxy:cell(level, x, y)
        return cells[level .. ":" .. x .. ":" .. y] or terrain.DNGN_FLOOR
    end

    -- Store only changed cells so the test can verify the entrance was painted
    -- without constructing a full dungeon level.
    function proxy:set_cell(level, x, y, feature)
        cells[level .. ":" .. x .. ":" .. y] = feature
    end

    -- Expose the ECS player to stock generation, which needs its item set
    -- state even though the map is only a proxy.
    function proxy:player()
        return player
    end

    return proxy
end

-- Place both fixed and source-authored shops through production generation,
-- then inspect ECS ownership and terrain to catch partial placement.
function test.run(ctx)
    local generation = require("policy.shops.generation")
    local player = ctx:create()

    item_sets.initialise(ctx, player)

    local grid = grid_context(ctx, player)
    -- A fixed shop request pins type, greed, count, and one entrance cell.
    local shop = generation.place(grid, {
        level_id = 1,
        x = 3,
        y = 2,
        depth = 2,
        kind_id = shop_ids.SHOP_WEAPON,
        greed = 12,
        count = 2,
        items = { item_ids.WPN_CLUB, item_ids.WPN_WHIP },
    })
    local state = ctx:get(shop, component.SHOP)

    harness.equal(state.kind_id, shop_ids.SHOP_WEAPON,
        "shop keeps resolved type")
    harness.equal(state.greed, 12, "source greed override")
    local keeper = names.from_seed(ctx, state.keeper_seed,
        name_modes.ORDINARY)

    harness.truthy(state.name:sub(1, #keeper + 3) == keeper .. "'s ",
        "ordinary shop displays the source-seeded keeper")
    harness.equal(generation.at(grid, 1, 3, 2), shop,
        "one shop owns its entrance")
    harness.equal(grid:cell(1, 3, 2), terrain.DNGN_ENTER_SHOP,
        "shop paints entrance terrain")

    local stock = ctx:query({ component.SHOP_STOCK })

    harness.equal(#stock, 2, "source stock count override")

    for _, entity in ipairs(stock) do
        local owner = ctx:get(entity, component.SHOP_STOCK)

        harness.equal(owner.shop_id, ctx:id(shop),
            "stock belongs to one shop")
        harness.falsy(ctx:has(entity, component.POSITION),
            "stock is not on floor")
    end

    -- Parsed source stock keeps an authored weapon plus rather than rerolling.
    local authored = shop_spec.parse(
        "weapon shop count:1 use_all ; club plus:3",
        {
            path = "vaults/shop/test_weapon.des",
            line = 5,
            vault_id = "test_weapon",
        })[1]

    authored.level_id = 1
    authored.x = 4
    authored.y = 2
    authored.depth = 2

    local authored_shop = generation.place(grid, authored)
    local authored_stock

    for _, entity in ipairs(ctx:query({ component.SHOP_STOCK })) do
        if ctx:get(entity, component.SHOP_STOCK).shop_id ==
            ctx:id(authored_shop) then
            authored_stock = ctx:get(entity, component.ITEM)
        end
    end

    harness.truthy(authored_stock, "authored shop has stock")
    harness.equal(authored_stock.kind_id, item_ids.WPN_CLUB,
        "authored stock keeps its item kind")
    harness.equal(authored_stock.plus, 3, "authored enchantment applied")

    -- Mixed source stock carries charges, enchantment, manuals, and uniques.
    local varied = shop_spec.parse(
        "general shop count:4 use_all ; " ..
        "wand of flame charges:11 | ring of protection plus:3 | " ..
        "manual of fire magic | randbook disc:fire numspells:8",
        {
            path = "vaults/shop/test_varied.des",
            line = 7,
            vault_id = "test_varied",
        })[1]

    varied.level_id = 1
    varied.x = 5
    varied.y = 2
    varied.depth = 10

    local varied_shop = generation.place(grid, varied)
    local varied_stock = {}

    for _, entity in ipairs(ctx:query({ component.SHOP_STOCK })) do
        local owner = ctx:get(entity, component.SHOP_STOCK)

        if owner.shop_id == ctx:id(varied_shop) then
            varied_stock[owner.order] = {
                entity = entity,
                item = ctx:get(entity, component.ITEM),
            }
        end
    end

    harness.equal(#varied_stock, 4, "varied source stock count")
    harness.equal(varied_stock[1].item.charges, 11,
        "authored wand charges")
    harness.equal(varied_stock[2].item.plus, 3,
        "authored ring enchantment")
    harness.equal(varied_stock[3].item.kind_id, item_ids.BOOK_MANUAL,
        "source manual becomes a manual")
    harness.truthy(ctx:has(varied_stock[4].entity,
        component.ITEM_RANDOM_BOOK), "source randbook has generated spells")

    -- Weighted shop alternatives use the same placement path on a fresh grid.
    local weighted_grid = grid_context(ctx, player)

    -- Force the rare branch on its exact roll bound while delegating other
    -- draws to the real context, keeping this scenario deterministic.
    function weighted_grid:random(stream, bound)
        if bound == 11 then
            return 10
        end

        return ctx:random(stream, bound)
    end

    local weighted = shop_spec.parse(
        "general shop count:1 ; club w:1 | whip w:10",
        {
            path = "vaults/shop/test_weighted.des",
            line = 9,
            vault_id = "test_weighted",
        })[1]

    weighted.level_id = 1
    weighted.x = 6
    weighted.y = 2
    weighted.depth = 2

    local weighted_shop = generation.place(weighted_grid, weighted)
    local weighted_item

    for _, entity in ipairs(ctx:query({ component.SHOP_STOCK })) do
        if ctx:get(entity, component.SHOP_STOCK).shop_id ==
            ctx:id(weighted_shop) then
            weighted_item = ctx:get(entity, component.ITEM)
        end
    end

    harness.equal(weighted_item.kind_id, item_ids.WPN_WHIP,
        "authored stock uses source item weights")

    -- A second shop cannot claim an occupied entrance; then every active
    -- shop definition is exercised through generation.
    local okay = pcall(generation.place, grid, {
        level_id = 1,
        x = 3,
        y = 2,
        depth = 2,
        kind_id = shop_ids.SHOP_ARMOUR,
        count = 1,
        items = { item_ids.ARM_BUCKLER },
    })

    harness.falsy(okay, "duplicate shop cell rejected")

    for index, definition in ipairs(catalog.all(categories.SHOPS)) do
        local generated = generation.place(grid, {
            level_id = 1,
            x = 10 + index,
            y = 3,
            depth = 3,
            kind_id = definition.id,
            count = 1,
        })
        local saved = ctx:get(generated, component.SHOP)

        harness.equal(saved.kind_id, definition.id,
            "active shop kind generates stock")
    end
end

return test
