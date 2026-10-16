local component = require("constants.component")
local capabilities = require("constants.jewellery_capabilities")
local items = require("policy.inventory.items")
local effects = require("policy.inventory.jewellery_effects")

local validation = {}

local function attunes(definition)
    local record = definition.jewellery
    local effects = record and record.effects or {}

    return effects[capabilities.HP_REGEN] ~= nil or
        effects[capabilities.MP_REGEN] ~= nil
end

function validation.run(ctx, player)
    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        local state = ctx:get(entity, component.JEWELLERY_ATTUNEMENT)
        local equipped = ctx:get(entity, component.EQUIPPED)
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local definition = items.kind(ctx:get(entity, component.ITEM))
        local worn_by_player = equipped and carrier and
            ctx:has(carrier.holder, component.PLAYER)
        local needs_state = worn_by_player and attunes(definition)

        if state and not needs_state then
            error("saved jewellery attunement has no worn owner")
        end

        if needs_state and not state then
            error("saved regeneration jewellery lacks attunement")
        end
    end

    if ctx:has(player, component.JEWELLERY_ACROBAT) and
        not effects.has(ctx, player, capabilities.ACROBAT) then
        error("saved acrobat state has no worn jewellery")
    end
end

return validation
