local component = require("constants.component")
local item_ids = require("ids.items")

local reservations = {}

local function listed_once(state, entity, ctx)
    local count = 0

    for _, offered in ipairs(state.offer_ids) do
        if ctx:id(offered) == ctx:id(entity) then
            count = count + 1
        end
    end

    return count == 1
end

function reservations.validate(ctx)
    for _, entity in ipairs(ctx:query({ component.RESERVED_BY })) do
        local reservation = ctx:get(entity, component.RESERVED_BY)
        local owner = reservation.owner
        local owner_item = ctx:get(owner, component.ITEM)
        local state = ctx:get(owner, component.SCROLL_ACQUIREMENT)

        if not owner_item or owner_item.kind_id ~= item_ids.SCR_ACQUIREMENT or
            not state or not listed_once(state, entity, ctx) then
            error("item " .. ctx:id(entity) ..
                " has no matching reservation menu reference")
        end
    end

    for _, owner in ipairs(ctx:query({ component.SCROLL_ACQUIREMENT })) do
        local state = ctx:get(owner, component.SCROLL_ACQUIREMENT)
        local seen = {}

        for _, entity in ipairs(state.offer_ids) do
            local id = ctx:id(entity)
            local reservation = ctx:get(entity, component.RESERVED_BY)

            if seen[id] or not reservation or
                ctx:id(reservation.owner) ~= ctx:id(owner) then
                error("acquirement menu has an invalid reservation reference")
            end

            seen[id] = true
        end
    end

    return {}
end

register.policy({
    id = "save.validate_reservations",
    run = reservations.validate,
})

return reservations
