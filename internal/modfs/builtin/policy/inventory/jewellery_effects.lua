local jewellery = require("policy.inventory.jewellery")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")
local component = require("constants.component")

local effects = {}
local known = {}
local needs_attunement = {
    [capabilities.HP_REGEN] = true,
    [capabilities.MP_REGEN] = true,
}

for _, capability in pairs(capabilities) do
    known[capability] = true
end

-- Fail on a misspelled capability at the query boundary; returning zero
-- would hide a broken item or policy registration.
local function require_capability(capability)
    if not known[capability] then
        error("unknown jewellery capability " .. tostring(capability))
    end
end

-- Resolve item-plus magnitudes from the live item component, since two rings
-- of one kind can carry different enchantment values.
-- Example: effects.value(ring_item, ring_definition, capabilities.AC).
function effects.value(item, definition, capability)
    require_capability(capability)

    local record = definition.jewellery
    local magnitude = record and record.effects and
        record.effects[capability]

    if magnitude == nil then
        return 0
    end

    if magnitude == magnitudes.ITEM_PLUS then
        return item.plus
    end

    return magnitude
end

-- Sum only worn items on usable slots. Regeneration capabilities wait for
-- attunement, preventing a newly equipped ring from acting immediately.
-- Example: effects.sum(ctx, player, capabilities.HP_REGEN).
function effects.sum(ctx, player, capability)
    require_capability(capability)

    -- Character creation and formula probes can run before player identity
    -- exists; no jewellery can be worn until slots are defined.
    if not ctx:has(player, "core.player") then
        return 0
    end

    local total = 0

    for _, entry in pairs(jewellery.worn(ctx, player)) do
        local state = needs_attunement[capability] and
            ctx:get(entry.entity, component.JEWELLERY_ATTUNEMENT)

        if not needs_attunement[capability] or
            (state and state.active) then
            total = total + effects.value(entry.item, entry.definition,
                capability)
        end
    end

    return total
end

-- Express boolean capabilities through the same aggregate calculation so
-- slot and attunement rules cannot diverge between callers.
function effects.has(ctx, player, capability)
    return effects.sum(ctx, player, capability) > 0
end

return effects
