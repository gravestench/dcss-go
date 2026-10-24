-- Ru measures action between sacrifice offers instead of accepting
-- ordinary kill piety. The player's saved religion.ru record owns this
-- progress through travel, death resolution, and restoration.
local component = require("constants.component")
local limits = require("constants.piety")
local streams = require("constants.rng_streams")

local progress = {}

-- Source mon-death.cc flips once for each credited XP kill below 200
-- piety. Ru's sacrifice cap is only 160; the source still uses 200 here.
function progress.on_kill(ctx, player, worship)
    if worship.piety >= limits.MAX then
        return
    end

    local state = ctx:get(player, component.RELIGION_RU)

    if not state then
        error("Ru kill progress requires saved sacrifice state")
    end

    if ctx:random(streams.RELIGION, 2) ~= 0 then
        return
    end

    state.sacrifice_progress = state.sacrifice_progress + 1
    ctx:set(player, component.RELIGION_RU, state)
end

return progress
