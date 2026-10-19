local classes = require("ids.object_classes")
local commands = require("policy.input.commands")
local identification = require("policy.items.identification")
local intent = require("constants.intent")
local items = require("policy.inventory.items")
local registry = require("policy.commands.registry")
local scrolls = require("policy.scrolls")
local restrictions = require("policy.scrolls.restrictions")

local read = {}

-- Scroll selection and read restrictions are resolved before consuming a turn.
-- Example: read.prepare(ctx, player, { item_id = scroll_id }) validates reading before use.
function read.prepare(ctx, player, input)
    local rejection = restrictions.reason(ctx, player)

    if rejection then
        return {
            message = rejection,
        }
    end

    local item_id = input.item_id or 0
    local entity = item_id ~= 0 and ctx:entity(item_id) or nil
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= player then
        return {
            message = "You are not carrying that scroll.",
        }
    end

    local kind = items.kind(item)
    items.validate(item, kind)

    if kind.class ~= classes.OBJ_SCROLLS then
        return {
            message = "You can't read that!",
        }
    end

    local effect = scrolls.get(item.kind_id)

    if not effect then
        return {
            message = "That scroll's effect is unavailable.",
        }
    end

    local request = {
        scroll = entity,
        known = identification.known(ctx, player, entity).type,
        target_id = input.target_id or "",
        dx = input.dx or 0,
        dy = input.dy or 0,
        cancelled = input.cancelled or false,
    }

    local decision = effect.prepare(ctx, player, request)

    if decision then
        return decision
    end

    return {
        intent = {
            kind = intent.READ,
            item_id = entity,
            target_id = request.target_id,
            dx = request.dx,
            dy = request.dy,
            cancelled = request.cancelled,
        },
        cost = 10,
    }
end

registry.register(commands.read, read.prepare)

return read
