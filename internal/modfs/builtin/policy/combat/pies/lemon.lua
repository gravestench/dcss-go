local component = require("constants.component")
local fillings = require("constants.pie_fillings")
local forms = require("policy.magic.effects.forms.player")
local restrictions = require("constants.safety_restrictions")
local safety = require("policy.character.damage_safety")

local lemon = {
    id = fillings.LEMON,
    weight = 10,
}

function lemon.valid(ctx, target)
    return ctx:has(target, component.PLAYER) and
        (forms.can_drink(ctx, target) or
            safety.active(ctx, target, restrictions.POTIONS))
end

function lemon.apply(ctx, _, target)
    safety.add_duration(ctx, target, restrictions.POTIONS,
        10 + ctx:random("monster_spell", 11), 50)
    ctx:emit("combat", "You feel unable to drink.")
end

return lemon
