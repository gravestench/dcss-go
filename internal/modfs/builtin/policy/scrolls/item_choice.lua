local component = require("constants.component")
local identification = require("policy.items.identification")
local selection = require("policy.scrolls.selection")

local choice = {}

local function reachable(ctx, player, entity)
    local carrier = ctx:get(entity, component.CARRIED_BY)

    if carrier then
        return carrier.holder == player
    end

    local floor = ctx:get(entity, component.POSITION)
    local position = ctx:get(player, component.POSITION)

    return floor and position and
        floor.x == position.x and floor.y == position.y
end

function choice.options(ctx, player, source, eligible)
    local options = {}

    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        if entity ~= source and reachable(ctx, player, entity) and
            eligible(ctx, player, entity) then
            options[#options + 1] = {
                id = tostring(ctx:id(entity)),
                label = identification.name(ctx, player, entity),
            }
        end
    end

    return options
end

function choice.prepare(ctx, player, request, title, no_items, eligible)
    local options = choice.options(ctx, player, request.scroll, eligible)

    return selection.prepare(request, "item", title, no_items, options)
end

function choice.target(ctx, request)
    return ctx:entity(tonumber(request.target_id))
end

return choice
