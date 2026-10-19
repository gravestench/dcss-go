local items = require("policy.inventory.items")
local equipment = require("policy.inventory.equipment")
local identification = require("policy.items.identification")

local system = {}

-- Theory of operation: The weapon slot changes after drop handling, so an item released this action is not still
-- equipped.
-- Wielding changes equipped components after drops have released any affected item.
function system.update(ctx, actor)
    local intent = ctx:get(actor, "core.intent")

    if not intent or intent.kind ~= 11 then
        return
    end

    if actor ~= ctx:player() then
        error("invalid wield actor " .. ctx:id(actor))
    end

    local entity = intent.item_id
    local item_id = entity and ctx:id(entity) or 0
    local current = equipment.in_slot(ctx, actor, "weapon")

    if current == entity then
        error("item " .. item_id .. " is already wielded")
    end

    local message = "You are now empty-handed."

    if item_id ~= 0 then
        local item = ctx:get(entity, "core.item")
        local carrier = ctx:get(entity, "core.carried_by")

        if not item or not carrier or carrier.holder ~= actor then
            error("wield actor " .. ctx:id(actor) .. " has invalid item " .. item_id)
        end

        local name = identification.name(ctx, actor, entity)
        message = "You are now wielding " .. items.phrase(name, 1) .. "."
    end

    if current then
        ctx:remove(current, "core.equipped")
    end

    if item_id ~= 0 then
        ctx:add(entity, "core.equipped", { slot = "weapon" })
    end

    ctx:emit("wield", message)
end

register.system({
    id = "item.wield",
    scope = "active",
    query = {},
    after = { "item.drop" },
    before = { "item.quaff" },
    update = system.update,
})

return system
