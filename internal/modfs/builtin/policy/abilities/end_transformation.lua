-- Source: ability.cc:ABIL_END_TRANSFORMATION and transform.cc:untransform.
local abilities = require("ids.abilities")
local component = require("constants.component")
local attributes = require("policy.character.attributes")
local forms = require("policy.magic.effects.forms.player")
local registry = require("policy.abilities.registry")

local ending = {}

-- Example: ending.available(ctx, player) hides End Transformation outside a cancellable form.
-- Read the current form component rather than catalog eligibility, because
-- only a live transformation with time remaining can be ended by the player.
function ending.available(ctx, player)
    local form = ctx:get(player, component.PLAYER_FORM)

    return form ~= nil and form.remaining_aut > 0
end

-- Warn only when ending the form can expose a zero current stat; ordinary
-- cancellations should not add a needless confirmation turn.
function ending.confirmation_needed(ctx, player)
    if not ending.available(ctx, player) then
        return false
    end

    local current = attributes.current(ctx, player)

    return current.strength == 0 or current.intelligence == 0 or
        current.dexterity == 0
end

-- Keep the warning text in the ability definition so preparation and UI
-- render the same risk instead of composing it in separate places.
function ending.confirmation_message()
    return "Ending your form may leave a stat at zero. Continue?"
end

-- Ask form policy for cancellation blockers first, then require a forced
-- confirmation when a stat could reach zero.
function ending.prepare(ctx, player, input)
    local rejection = forms.end_rejection(ctx, player)

    if rejection then
        return rejection
    end

    if ending.confirmation_needed(ctx, player) and not input.forced then
        return ending.confirmation_message()
    end

    return nil
end

-- Finish through the form owner, which restores all changed attributes and
-- equipment constraints as one transition.
function ending.resolve(ctx, player)
    forms.finish(ctx, player)
end

registry.add(abilities.END_TRANSFORMATION, {
    name = "End Transformation",
    available = ending.available,
    confirmation_needed = ending.confirmation_needed,
    confirmation_message = ending.confirmation_message,
    prepare = ending.prepare,
    resolve = ending.resolve,
})

return ending
