local component = require("constants.component")
local fillings = require("constants.pie_fillings")
local statuses = require("policy.magic.effects.statuses.player")

local plum = {
    id = fillings.PLUM,
    weight = 10,
}

-- Example: plum.valid(ctx, target) with monster target -> false eligibility
-- Only players receive the vertigo status, so monster targets are excluded from plum selection.
function plum.valid(ctx, target)
    return ctx:has(target, component.PLAYER)
end

-- Plum pie gives player vertigo with a random duration and a fixed strength.
function plum.apply(ctx, _, target)
    statuses.add_vertigo(ctx, target,
        10 + ctx:random("monster_spell", 11), 50)
    ctx:emit("combat", "You feel light-headed.")
end

return plum
