local items = require("ids.items")
local potions = require("policy.potions")
local flight = require("policy.combat.flight")
local forms = require("policy.magic.effects.forms.player")
local component = require("constants.component")

local effect = {}

function effect.can_quaff(ctx, player)
    if forms.modifiers(ctx, player).flight ~= "forbid" then
        return nil
    end

    local form = ctx:get(player, component.PLAYER_FORM)

    if form and form.form_id == "tree" then
        return "Your roots keep you in place."
    end

    return "You can't fly in this form."
end

-- Source: player.cc:fly_player and potion.cc:PotionFlight::effect.
function effect.apply(ctx, player)
    local airborne = flight.active(ctx, player)
    local state = ctx:get(player, component.ZAP_FLIGHT)
    local added = (25 + ctx:random("potion", 40)) * 10

    if state then
        state.remaining_aut = math.min(1000,
            state.remaining_aut + added)
        ctx:set(player, component.ZAP_FLIGHT, state)
    else
        ctx:add(player, component.ZAP_FLIGHT, {
            remaining_aut = added,
        })
    end

    if airborne then
        return "You feel more buoyant."
    end

    return "You feel very buoyant."
end

potions.register(items.POT_FLIGHT, effect)

return effect
