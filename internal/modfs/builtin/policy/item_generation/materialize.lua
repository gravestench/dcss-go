local catalog = require("policy.catalog")
local component = require("constants.component")
local items = require("policy.inventory.items")

local materialize = {}

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

    return count
end

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
    elseif location.carrier == 0 or location.reservation == 0 then
        error("generated item location owner cannot be zero")
    end
end

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
    else
        ctx:add(entity, component.RESERVED_BY, {
            owner = location.reservation,
        })
    end

    return entity
end

return materialize
