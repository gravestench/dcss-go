-- Source entry bonuses summon friendly zombies until a piety star target.
-- That entity work belongs to the later Yred soul owner; this component
-- keeps the target through save/restore in the meantime.
local component = require("constants.component")

local yred = {}

-- Preserve the larger of any pending requests without duplicating zombies.
local function queue(ctx, player, stars)
    local state = ctx:get(player, component.RELIGION_YREDELEMNUL)

    if state then
        state.pending_bonus_stars = math.max(
            state.pending_bonus_stars,
            stars)
        ctx:set(player, component.RELIGION_YREDELEMNUL, state)
    else
        ctx:add(player, component.RELIGION_YREDELEMNUL, {
            pending_bonus_stars = stars,
        })
    end
end

-- A first-god Monk receives enough zombies to reach two stars.
function yred.monk_bonus(ctx, player)
    queue(ctx, player, 2)
end

-- An unknown altar grants a one-star zombie target.
function yred.ecumenical_bonus(ctx, player)
    queue(ctx, player, 1)
end

return yred
