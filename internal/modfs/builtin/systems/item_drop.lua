local items = require("policy.inventory.items")
local identification = require("policy.items.identification")

local system = {}

-- Theory of operation: The intent validates ownership before reducing a stack or clearing its carried component.
-- Dropping transfers or splits carried stacks before later equipment actions can inspect them.
function system.update(ctx, actor)
    local intent = ctx:get(actor, "core.intent")

    if not intent or intent.kind ~= 10 then
        return
    end

    local entity = intent.item_id
    local item = ctx:get(entity, "core.item")
    local carrier = ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= actor or
        intent.quantity <= 0 or intent.quantity > item.quantity then
        error("drop actor " .. ctx:id(actor) .. " has invalid item " .. ctx:id(entity))
    end

    local position = ctx:get(actor, "core.position")

    if not position then
        error("drop actor " .. ctx:id(actor) .. " has no position")
    end

    local name = identification.name(ctx, ctx:player(), entity)
    local floor = items.floor_stack(ctx, position, item, entity)

    -- Merge with a matching floor stack; a partial unstacked drop gets a new entity and copied knowledge.
    if floor then
        local stacked = ctx:get(floor, "core.item")
        stacked.quantity = stacked.quantity + intent.quantity
        ctx:set(floor, "core.item", stacked)

        if intent.quantity == item.quantity then
            ctx:destroy(entity)
        else
            item.quantity = item.quantity - intent.quantity
            ctx:set(entity, "core.item", item)
        end
    elseif intent.quantity == item.quantity then
        ctx:remove(entity, "core.equipped")
        ctx:remove(entity, "core.carried_by")
        ctx:add(entity, "core.position", position)
    else
        local dropped = ctx:create()
        local copy = {
            kind_id = item.kind_id,
            quantity = intent.quantity,
            plus = item.plus,
            charges = item.charges,
            ego = item.ego,
        }

        ctx:add(dropped, "core.item", copy)
        identification.copy(ctx, entity, dropped)
        ctx:add(dropped, "core.position", position)
        item.quantity = item.quantity - intent.quantity
        ctx:set(entity, "core.item", item)
    end

    ctx:emit("drop", "You drop " .. items.phrase(name, intent.quantity) .. ".")
end

register.system({
    id = "item.drop",
    scope = "active",
    query = {},
    after = { "item.pickup" },
    before = { "item.wield" },
    update = system.update,
})

return system
