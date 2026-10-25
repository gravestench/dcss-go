-- Ru's sacrifices are an offer queue, not ordinary piety income. Source
-- conversion clears old choices before bonus progress is applied.
local component = require("constants.component")

local ru = {}

-- Reset the five source candidate vectors and the first-offer timer.
function ru.prepare(ctx, player)
    local previous = ctx:get(player, component.RELIGION_RU)

    local state = {
        sacrifice_progress = 0,
        sacrifice_delay = 50,
        sacrifice_penalty = 0,
        -- Source join resets the offer clock, not the lifetime count.
        sacrifice_mutations = previous and
            previous.sacrifice_mutations or 0,
        available = {},
        health = {},
        essence = {},
        purity = {},
        arcana = {},
        quoted_piety = {},
    }

    if previous then
        ctx:set(player, component.RELIGION_RU, state)
    else
        ctx:add(player, component.RELIGION_RU, state)
    end
end

-- A Monk's first patron should have an offer ready immediately.
function ru.monk_bonus(ctx, player)
    local state = ctx:get(player, component.RELIGION_RU) or {}

    state.sacrifice_progress = 9999

    if ctx:get(player, component.RELIGION_RU) then
        ctx:set(player, component.RELIGION_RU, state)
    else
        ctx:add(player, component.RELIGION_RU, state)
    end
end

-- The unknown altar awards the same immediate source offer progress.
function ru.ecumenical_bonus(ctx, player)
    local state = ctx:get(player, component.RELIGION_RU)

    state.sacrifice_progress = 9999
    ctx:set(player, component.RELIGION_RU, state)
end

return ru
