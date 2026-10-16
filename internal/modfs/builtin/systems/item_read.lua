local component = require("constants.component")
local identification = require("policy.items.identification")
local intent_kind = require("constants.intent")
local scrolls = require("policy.scrolls")

local system = {}

function system.update(ctx, actor)
    local intent = ctx:get(actor, component.INTENT)

    if not intent or intent.kind ~= intent_kind.READ then
        return
    end

    local player = ctx:player()

    if actor ~= player or not intent.item_id then
        error("unsupported scroll reader or item")
    end

    local item = ctx:get(intent.item_id, component.ITEM)
    local carrier = ctx:get(intent.item_id, component.CARRIED_BY)

    if not item or not carrier or carrier.holder ~= player or
        item.quantity <= 0 then
        error("scroll is no longer carried")
    end

    local effect = scrolls.get(item.kind_id)

    if not effect then
        error("unsupported scroll " .. item.kind_id)
    end

    local visible_name = identification.name(ctx, player, intent.item_id)
    local request = {
        scroll = intent.item_id,
        target_id = intent.target_id,
        dx = intent.dx,
        dy = intent.dy,
        cancelled = intent.cancelled,
    }

    ctx:emit("read", "As you read the " .. visible_name ..
        ", it crumbles to dust.")

    if not request.cancelled then
        effect.apply(ctx, player, request)
    end

    identification.reveal_type(ctx, player, intent.item_id)

    if item.quantity == 1 then
        ctx:destroy(intent.item_id)
    else
        item.quantity = item.quantity - 1
        ctx:set(intent.item_id, component.ITEM, item)
    end
end

register.system({
    id = "item.read",
    scope = "active",
    query = {},
    after = { "item.quaff" },
    before = { "world.doors" },
    update = system.update,
})

return system
