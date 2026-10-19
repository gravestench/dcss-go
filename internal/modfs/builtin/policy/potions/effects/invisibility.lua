local component = require("constants.component")
local items = require("ids.items")
local potions = require("policy.potions")
local invisibility = require("policy.potions.invisibility")

local effect = {}

-- Backlighting prevents invisibility even if the potion could extend a timer.
function effect.can_quaff(ctx, player)
    if invisibility.backlit(ctx, player) then
        return "Your glow prevents you from becoming invisible."
    end
end

-- Source: potion.cc:PotionInvisibility::effect. Repeated drinks add a
-- separate zero-to-39-turn roll and total duration is capped at 100 turns.
-- Example: a second Invisibility potion extends its saved duration rather than adding another status.
function effect.apply(ctx, player, stream)
    local state = ctx:get(player, component.POTION_INVISIBILITY)
    local roll = ctx:random(stream or "potion", 40) * 10

    if state then
        state.remaining_aut = math.min(1000,
            state.remaining_aut + roll)
        ctx:set(player, component.POTION_INVISIBILITY, state)
        return "You fade further into invisibility."
    end

    ctx:add(player, component.POTION_INVISIBILITY, {
        remaining_aut = 150 + roll,
    })

    return "You fade into invisibility!"
end

potions.register(items.POT_INVISIBILITY, effect)

return effect
