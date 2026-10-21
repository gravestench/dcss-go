local categories = require("constants.catalog")
local component = require("constants.component")
local content = require("policy.catalog")
local classes = require("ids.object_classes")
local terrain = require("constants.terrain")
local effects = require("constants.vault_effects")
local shop_spec = require("policy.generation.vaults.shop_spec")

local shops = {}

-- Shop locations use floor and cell coordinates to reject overlapping saved shops.
local function cell_key(state)
    return string.format("%d:%d:%d", state.level_id, state.x, state.y)
end

-- Gold balances must be nonnegative whole values before pricing resumes.
local function valid_balance(value)
    return type(value) == "number" and value % 1 == 0 and
        value >= 0 and value <= 9007199254740991
end

-- Bound both wallet gold and purchase count, then verify shopping-list item references.
local function validate_wallet(ctx)
    local player = ctx:player()
    local wallet = ctx:get(player, component.WALLET)
    local list = ctx:get(player, component.SHOPPING_LIST)

    if not wallet or not valid_balance(wallet.gold) or
        not valid_balance(wallet.purchases) or
        not valid_balance(wallet.generated_gold) then
        error("player has an invalid shop wallet")
    end

    if not list then
        error("player lacks a shopping list")
    end

    local seen = {}

    for _, stock in ipairs(list.stock_ids) do
        local id = ctx:id(stock)

        if seen[id] or not ctx:has(stock, component.SHOP_STOCK) then
            error("shopping list has an invalid shop stock reference")
        end

        seen[id] = true
    end
end

-- A new floor may still have pending shop records. Once populated, each
-- authored shop entrance must have exactly one saved shop entity.
local function authored_cells(ctx, input)
    local cells = {}
    local seen = {}

    for _, level in ipairs(input.levels or {}) do
        for _, record in ipairs(level.vault_records or {}) do
            if record.kind == effects.FEATURE and
                not record.overridden and
                shop_spec.is_shop(record.identity) then
                local key = string.format("%d:%d:%d",
                    level.id, record.x, record.y)

                if seen[key] or
                    (record.pending and level.initial_actors ~= 0) or
                    (not record.pending and level.initial_actors == 0) then
                    error("authored shop record has invalid population state " .. key)
                end

                seen[key] = true

                if not record.pending then
                    local cell = ctx:cell(level.id, record.x, record.y)

                    if cell == terrain.DNGN_ENTER_SHOP then
                        cells[key] = true
                    else
                        local site = {
                            path = record.arguments and record.arguments.path or
                                "vaults/shop/" .. record.source_id .. ".des",
                            vault_id = record.source_id,
                            line = record.line,
                        }
                        local floor_allowed = false

                        for _, alternative in ipairs(shop_spec.parse(
                            record.identity, site)) do
                            if not alternative.kind_id then
                                floor_allowed = true
                            end
                        end

                        if not floor_allowed or cell ~= terrain.DNGN_FLOOR then
                            error("authored shop choice lost its floor cell " .. key)
                        end
                    end
                end
            end
        end
    end

    return cells
end

-- Saved shop entities must occupy distinct authored entrance cells with known kinds.
local function validate_shops(ctx, input)
    local occupied = {}
    local authored = authored_cells(ctx, input)
    local generated = input.scenario_id == "generated-dungeon-basic-v1"

    for _, entity in ipairs(ctx:query({ component.SHOP })) do
        local state = ctx:get(entity, component.SHOP)
        local known = pcall(content.get, categories.SHOPS, state.kind_id)
        local key = cell_key(state)

        if not known or state.greed < 0 or state.name == "" or
            not ctx:walkable(state.level_id, state.x, state.y) or
            ctx:cell(state.level_id, state.x, state.y) ~= terrain.DNGN_ENTER_SHOP or
            occupied[key] or (generated and not authored[key]) then
            error("shop " .. ctx:id(entity) .. " has invalid placement or kind")
        end

        occupied[key] = true
    end

    for key in pairs(authored) do
        if not occupied[key] then
            error("authored shop record has no shop entity at " .. key)
        end
    end
end

-- Shop stock must resolve to saved item entities before purchases resume.
local function validate_stock(ctx)
    local ordered = {}

    for _, entity in ipairs(ctx:query({ component.SHOP_STOCK })) do
        local state = ctx:get(entity, component.SHOP_STOCK)
        local owner = ctx:entity(state.shop_id)
        local item = ctx:get(entity, component.ITEM)

        if not owner or not ctx:has(owner, component.SHOP) or
            not item or item.quantity <= 0 or
            content.get(categories.ITEMS, item.kind_id).class == classes.OBJ_GOLD or
            ctx:has(entity, component.POSITION) or
            ctx:has(entity, component.CARRIED_BY) or
            ctx:has(entity, component.RESERVED_BY) or
            state.order < 1 then
            error("shop stock " .. ctx:id(entity) .. " has invalid owner or location")
        end

        local key = tostring(state.shop_id) .. ":" .. tostring(state.order)

        if ordered[key] then
            error("duplicate shop stock order " .. key)
        end

        ordered[key] = true
    end
end

-- Wallet, stock, and authored shop cells are validated together to keep purchases resumable.
-- Example: shops.validate(ctx, input) checks that saved stock belongs to the declared shop.
function shops.validate(ctx, input)
    input = input or {}

    validate_wallet(ctx)
    validate_shops(ctx, input)
    validate_stock(ctx)

    return {}
end

register.policy({
    id = "save.validate_shops",
    run = shops.validate,
})

return shops
