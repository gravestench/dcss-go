-- Source: ability.cc:ABIL_END_TRANSFORMATION and transform.cc:untransform.
local abilities = require("ids.abilities")
local component = require("constants.component")
local attributes = require("policy.character.attributes")
local forms = require("policy.magic.effects.forms.player")
local registry = require("policy.abilities.registry")

local ending = {}

function ending.available(ctx, player)
    local form = ctx:get(player, component.PLAYER_FORM)

    return form ~= nil and form.remaining_aut > 0
end

function ending.confirmation_needed(ctx, player)
    if not ending.available(ctx, player) then
        return false
    end

    local current = attributes.current(ctx, player)

    return current.strength == 0 or current.intelligence == 0 or
        current.dexterity == 0
end

function ending.confirmation_message()
    return "Ending your form may leave a stat at zero. Continue?"
end

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
