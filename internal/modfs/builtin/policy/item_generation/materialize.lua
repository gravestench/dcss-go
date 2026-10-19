local catalog = require("policy.catalog")
local component = require("constants.component")
local items = require("policy.inventory.items")

local materialize = {}

-- A generated item may be floor stock, carried, reserved, or shop stock; accepting two owners would corrupt saves.
local function location_count(location)
    local count = 0

    if location.position then
        count = count + 1
    end

    if location.carrier then
        count = count + 1
    end

    if location.reservation then
        count = count + 1
    end

    if location.shop then
        count = count + 1
    end

    return count
end

-- Exactly one placement mode is required; shop stock also needs a positive order.
local function validate_location(location)
    if type(location) ~= "table" or location_count(location) ~= 1 then
        error("generated item requires exactly one location")
    end

    if location.position then
        local position = location.position

        if type(position.level_id) ~= "number" or
            type(position.x) ~= "number" or
            type(position.y) ~= "number" then
            error("generated item has invalid position")
        end
    elseif location.carrier == 0 or location.reservation == 0 or
        location.shop == 0 then
        error("generated item location owner cannot be zero")
    elseif location.shop and
        (type(location.order) ~= "number" or
        location.order < 1 or location.order % 1 ~= 0) then
        error("generated shop stock requires a positive order")
    end
end

-- Example: materialize.create(ctx, result, { level_id = floor, x = 2, y = 3 }) places a generated item.
-- Extra components are added in sorted name order so generation stays deterministic.
function materialize.create(ctx, result, location)
    validate_location(location)

    local definition = catalog.get("items", result.kind_id)
    local item = {
        kind_id = result.kind_id,
        quantity = result.quantity,
        plus = result.plus,
        charges = result.charges,
        ego = result.ego,
    }

    items.validate(item, definition)

    local entity = ctx:create()

    ctx:add(entity, component.ITEM, item)

    local names = {}

    for name in pairs(result.components or {}) do
        names[#names + 1] = name
    end

    table.sort(names)

    for _, name in ipairs(names) do
        ctx:add(entity, name, result.components[name])
    end

    if location.position then
        ctx:add(entity, component.POSITION, location.position)
    elseif location.carrier then
        ctx:add(entity, component.CARRIED_BY, {
            holder = location.carrier,
        })
    elseif location.reservation then
        ctx:add(entity, component.RESERVED_BY, {
            owner = location.reservation,
        })
    else
        ctx:add(entity, component.SHOP_STOCK, {
            shop_id = ctx:id(location.shop),
            order = location.order,
        })
    end

    return entity
end

return materialize
