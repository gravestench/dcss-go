local component = require("constants.component")
local capabilities = require("constants.jewellery_capabilities")
local effects = require("policy.inventory.jewellery_effects")

local acrobat = {}

local function set_active(ctx, player, active)
    if not effects.has(ctx, player, capabilities.ACROBAT) then
        if ctx:has(player, component.JEWELLERY_ACROBAT) then
            ctx:remove(player, component.JEWELLERY_ACROBAT)
        end

        return
    end

    local value = { active = active }

    if ctx:has(player, component.JEWELLERY_ACROBAT) then
        ctx:set(player, component.JEWELLERY_ACROBAT, value)
    else
        ctx:add(player, component.JEWELLERY_ACROBAT, value)
    end
end

function acrobat.begin_action(ctx, player, waiting)
    set_active(ctx, player, waiting)
end

function acrobat.moved(ctx, player)
    set_active(ctx, player, true)
end

function acrobat.equipment_changed(ctx, player)
    if not effects.has(ctx, player, capabilities.ACROBAT) and
        ctx:has(player, component.JEWELLERY_ACROBAT) then
        ctx:remove(player, component.JEWELLERY_ACROBAT)
    end
end

function acrobat.bonus(ctx, player)
    local state = ctx:get(player, component.JEWELLERY_ACROBAT)

    if not state or not state.active or
        ctx:has(player, component.CONSTRICTION) or
        not effects.has(ctx, player, capabilities.ACROBAT) then
        return 0
    end

    return 15
end

return acrobat
