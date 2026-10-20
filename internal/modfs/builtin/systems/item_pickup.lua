local items = require("policy.inventory.items")
local identification = require("policy.items.identification")
local wallet = require("policy.shops.wallet")
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local runes = require("policy.character.runes")

local system = {}

-- Theory of operation: Floor gold becomes wallet value while item entities become carried stacks before drop handling.
-- Pickup handles gold through the wallet and items through carried components before drop actions.
function system.update(ctx, actor)
    local intent = ctx:get(actor, "core.intent")

    if not intent or intent.kind ~= 3 then
        return
    end

    local position = ctx:get(actor, "core.position")

    if not position then
        error("pickup actor " .. ctx:id(actor) .. " has no position")
    end

    for _, entity in ipairs(items.at(ctx, position)) do
        if not ctx:has(entity, "core.corpse") then
            local item = ctx:get(entity, "core.item")
            local name = identification.name(ctx, ctx:player(), entity)
            local definition = catalog.get("items", item.kind_id)

            if definition.class == classes.OBJ_GOLD then
                local amount = wallet.pickup(ctx, actor, entity)

                ctx:emit("pickup", "You pick up " .. amount .. " gold pieces.")

                return
            end

            -- Source runes become permanent character progress on pickup;
            -- their floor entity does not turn into an inventory stack.
            if definition.class == classes.OBJ_RUNES then
                runes.collect(ctx, actor, item.kind_id)
                ctx:destroy(entity)
                ctx:emit("pickup", "You pick up " .. items.phrase(name, 1) .. ".")

                return
            end

            local stack = items.carried_stack(ctx, actor, entity)

            if stack then
                local carried = ctx:get(stack, "core.item")
                carried.quantity = carried.quantity + item.quantity
                ctx:set(stack, "core.item", carried)
                ctx:destroy(entity)
            else
                ctx:remove(entity, "core.position")
                ctx:add(entity, "core.carried_by", { holder = actor })
            end

            ctx:emit("pickup", "You pick up " .. items.phrase(name, item.quantity) .. ".")

            return
        end
    end

    error("pickup actor " .. ctx:id(actor) .. " has no floor item")
end

register.system({
    id = "item.pickup",
    scope = "active",
    query = {},
    before = { "item.drop" },
    update = system.update,
})

return system
