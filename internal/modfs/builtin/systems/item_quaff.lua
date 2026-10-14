local potions = require("policy.potions")

register.system({
    id = "item.quaff",
    scope = "active",
    query = {},
    after = { "item.wield" },
    before = { "world.doors" },
    update = function(ctx, actor)
        local intent = ctx:get(actor, "core.intent")

        if not intent or intent.kind ~= 7 then
            return
        end

        local player = ctx:player()

        if actor ~= player or not intent.item_id then
            error("unsupported quaff actor or item")
        end

        local item = ctx:get(intent.item_id, "core.item")
        local carrier = ctx:get(intent.item_id, "core.carried_by")

        if not item or not carrier or carrier.holder ~= player or
            item.quantity <= 0 then
            error("potion is no longer carried")
        end

        local effect = potions[item.kind_id]

        if not effect then
            error("unsupported potion " .. item.kind_id)
        end

        local message = effect(ctx, player)

        if item.quantity == 1 then
            ctx:destroy(intent.item_id)
        else
            item.quantity = item.quantity - 1
            ctx:set(intent.item_id, "core.item", item)
        end

        ctx:emit("quaff", message)
    end,
})
