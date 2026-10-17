local harness = require("tests.harness")
local component = require("constants.component")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local item_ids = require("ids.items")
local item_sets = require("policy.item_generation.item_sets")
local shop_ids = require("ids.shops")
local terrain = require("constants.terrain")

local test = {}

local function grid_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })
    local cells = {}

    function proxy:walkable(_, x, y)
        return x > 0 and y > 0
    end

    function proxy:cell(level, x, y)
        return cells[level .. ":" .. x .. ":" .. y] or terrain.DNGN_FLOOR
    end

    function proxy:set_cell(level, x, y, feature)
        cells[level .. ":" .. x .. ":" .. y] = feature
    end

    function proxy:player()
        return player
    end

    return proxy
end

function test.run(ctx)
    local generation = require("policy.shops.generation")
    local player = ctx:create()

    item_sets.initialise(ctx, player)

    local grid = grid_context(ctx, player)
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
