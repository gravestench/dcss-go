local component = require("constants.component")
local fillings = require("constants.pie_fillings")
local statuses = require("policy.magic.effects.statuses.player")

local plum = {
    id = fillings.PLUM,
    weight = 10,
}

function plum.valid(ctx, target)
    return ctx:has(target, component.PLAYER)
end

function plum.apply(ctx, _, target)
    statuses.add_vertigo(ctx, target,
        10 + ctx:random("monster_spell", 11), 50)
    ctx:emit("combat", "You feel light-headed.")
end

return plum
