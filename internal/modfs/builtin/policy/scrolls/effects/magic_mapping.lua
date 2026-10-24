-- Source: item-use.cc and view.cc:magic_mapping(500, 100, false).
local item_ids = require("ids.items")
local mapping = require("policy.world.magic_mapping")
local scrolls = require("policy.scrolls")

local effect = {}

-- Known scrolls decline in unmappable branches before issuing an action.
function effect.prepare(ctx, player, request)
    if request.known and not mapping.persistent(ctx, player) then
        return {
            message = "It would have no effect in this place.",
        }
    end

    return nil
end

-- Example: Magic Mapping marks every cell on the current mappable level as explored.
-- Map every cell only in persistent-map branches; otherwise emit the transient failure message.
function effect.apply(ctx, player)
    if not mapping.persistent(ctx, player) then
        ctx:emit("read", "You feel momentarily disoriented.")

        return
    end

    mapping.full(ctx, player, "item")

    ctx:emit("read", "You feel aware of your surroundings.")
end

scrolls.register(item_ids.SCR_MAGIC_MAPPING, effect)

return effect
