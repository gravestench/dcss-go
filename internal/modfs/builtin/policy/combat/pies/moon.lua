local component = require("constants.component")
local fillings = require("constants.pie_fillings")
local forms = require("policy.magic.effects.forms.player")
local polymorph = require("policy.magic.effects.statuses.polymorph")

local moon = {
    id = fillings.MOON,
    weight = 4,
}

function moon.valid(ctx, target)
    if ctx:has(target, component.PLAYER) then
        return forms.can_polymorph(ctx, target)
    end

    return polymorph.can_actor(ctx, target)
end

function moon.apply(ctx, _, target)
    if ctx:has(target, component.PLAYER) then
        forms.polymorph(ctx, target, 100)
    else
        local actor = ctx:get(target, component.ACTOR)
        local definition = require("policy.catalog").get(
            "monsters", actor.kind_id)

        polymorph.shapeshift(ctx, target, definition)
    end
end

return moon
