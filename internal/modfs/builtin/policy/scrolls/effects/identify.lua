local classes = require("ids.object_classes")
local catalog = require("policy.catalog")
local component = require("constants.component")
local identification = require("policy.items.identification")
local items = require("ids.items")
local choice = require("policy.scrolls.item_choice")
local scrolls = require("policy.scrolls")

local identify = {}

-- Offer an item while its type or any inspectable property is still unknown.
local function eligible(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)

    local state = identification.known(ctx, player, entity)

    if not state.type then
        return true
    end

    local kind = catalog.get("items", item.kind_id)

    return (kind.class == classes.OBJ_WEAPONS or
        kind.class == classes.OBJ_ARMOUR or
        kind.class == classes.OBJ_JEWELLERY or
        kind.class == classes.OBJ_STAVES) and
        (not state.pluses or not state.properties)
end

-- Only still-unknown items enter the identify target menu.
-- Example: Identify offers carried or nearby items whose type or properties remain unknown.
-- Use the reachable-item selector to exclude fully known items and the scroll itself.
function identify.prepare(ctx, player, request)
    return choice.prepare(ctx, player, request,
        "Identify which item?", "You have nothing to identify.",
        eligible)
end

-- Reveal the type, then pluses and properties for equipment classes after the read action.
function identify.apply(ctx, player, request)
    local target = choice.target(ctx, request)
    local item = ctx:get(target, component.ITEM)
    local kind = catalog.get("items", item.kind_id)

    identification.reveal_type(ctx, player, target)

    if kind.class == classes.OBJ_WEAPONS or
        kind.class == classes.OBJ_ARMOUR or
        kind.class == classes.OBJ_JEWELLERY or
        kind.class == classes.OBJ_STAVES then
        identification.reveal_item(ctx, target, {
            pluses = true,
            properties = true,
        })
    end

    ctx:emit("read", identification.name(ctx, player, target))
end

scrolls.register(items.SCR_IDENTIFY, identify)

return identify
