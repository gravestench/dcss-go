local items = require("policy.inventory.items")

register.system({
    id = "item.pickup",
    scope = "active",
    query = {},
    before = { "item.drop" },
    update = function(ctx, actor)
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
                local kind = items.kind(item)
                local stack = items.carried_stack(ctx, actor, item)

                if stack then
                    local carried = ctx:get(stack, "core.item")
                    carried.quantity = carried.quantity + item.quantity
                    ctx:set(stack, "core.item", carried)
                    ctx:destroy(entity)
                else
                    ctx:remove(entity, "core.position")
                    ctx:add(entity, "core.carried_by", { holder = actor })
                end

                ctx:emit("pickup", "You pick up " .. items.phrase(kind.name, item.quantity) .. ".")

                return
            end
        end

        error("pickup actor " .. ctx:id(actor) .. " has no floor item")
    end,
})
