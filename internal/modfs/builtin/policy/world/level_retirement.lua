-- A retired one-visit region may contain shop stock the player marked for
-- purchase. Remove those saved references before the engine destroys the
-- stock, or save validation would retain dangling entity handles.
local component = require("constants.component")

local retirement = {}

-- Keep the player's shopping list in its ordinary ECS component. The Go
-- level owner supplies exactly the entity IDs it is about to retire.
function retirement.prune_stock(ctx, input)
    local player = ctx:player()
    local list = ctx:get(player, component.SHOPPING_LIST)

    if not list then
        return {}
    end

    local retired = {}

    for _, id in ipairs(input.entity_ids or {}) do
        retired[id] = true
    end

    local kept = {}

    for _, stock in ipairs(list.stock_ids) do
        if not retired[ctx:id(stock)] then
            kept[#kept + 1] = stock
        end
    end

    list.stock_ids = kept
    ctx:set(player, component.SHOPPING_LIST, list)

    return {}
end

register.policy({
    id = "world.prune_retired_stock",
    run = retirement.prune_stock,
})

return retirement
