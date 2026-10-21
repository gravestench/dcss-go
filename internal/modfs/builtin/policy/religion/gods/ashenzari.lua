-- Ashenzari starts with little piety; binding equipment through curses is
-- the later source of devotion. Entry only schedules that owner state.
local component = require("constants.component")

local ashenzari = {}

-- Initialize the source 20-turn offer delay on each fresh conversion.
function ashenzari.prepare(ctx, player)
    local state = {
        curse_progress = 0,
        curse_delay = 20,
        offer_pending = false,
    }

    if ctx:get(player, component.RELIGION_ASHENZARI) then
        ctx:set(player, component.RELIGION_ASHENZARI, state)
    else
        ctx:add(player, component.RELIGION_ASHENZARI, state)
    end
end

-- A first-god Monk is owed an early curse offer; save that obligation.
function ashenzari.monk_bonus(ctx, player)
    local state = ctx:get(player, component.RELIGION_ASHENZARI) or {}

    state.curse_progress = 19
    state.offer_pending = true

    if ctx:get(player, component.RELIGION_ASHENZARI) then
        ctx:set(player, component.RELIGION_ASHENZARI, state)
    else
        ctx:add(player, component.RELIGION_ASHENZARI, state)
    end
end

-- An unknown altar advances the curse offer immediately, after join setup.
function ashenzari.ecumenical_bonus(ctx, player)
    local state = ctx:get(player, component.RELIGION_ASHENZARI)

    state.curse_progress = 9999
    state.offer_pending = true
    ctx:set(player, component.RELIGION_ASHENZARI, state)
end

return ashenzari
