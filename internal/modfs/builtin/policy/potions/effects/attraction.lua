local items = require("ids.items")
local potions = require("policy.potions")
local component = require("constants.component")

local effect = {}

-- Attraction can extend an existing aura, so preflight does not reject repeated use.
function effect.can_quaff()
    return nil
end

-- Source: potion.cc:PotionAttraction::effect.
-- Example: drinking Attraction extends the saved pull duration when the aura is already active.
function effect.apply(ctx, player)
    local state = ctx:get(player, component.POTION_ATTRACTION)
    local added = (20 + math.floor(ctx:random("potion", 40) / 2)) * 10

    if state then
        state.remaining_aut = state.remaining_aut + added
        ctx:set(player, component.POTION_ATTRACTION, state)
        return "You feel more attractive to monsters."
    end

    ctx:add(player, component.POTION_ATTRACTION, {
        remaining_aut = added,
    })

    return "You feel attractive to monsters."
end

potions.register(items.POT_ATTRACTION, effect)

return effect
