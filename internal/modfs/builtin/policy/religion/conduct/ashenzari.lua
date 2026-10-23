-- Ashenzari's exploration conduct advances the saved curse-offer clock;
-- it never gives ordinary piety. A missing component means conversion did
-- not initialize the god's state and is treated as a rule error.
local component = require("constants.component")
local kinds = require("constants.religion_conduct")
local streams = require("constants.rng_streams")

-- One in a hundred source exploration pulses advances the offer.
local function explore(ctx, player)
    local state = ctx:get(player, component.RELIGION_ASHENZARI)

    if not state then
        error("Ashenzari conduct requires saved curse state")
    end

    if ctx:random(streams.RELIGION, 100) == 0 then
        state.curse_progress = state.curse_progress + 1
        ctx:set(player, component.RELIGION_ASHENZARI, state)
    end

    return 0, 1
end

local ashenzari = {
    likes = {
        [kinds.EXPLORATION] = {
            bonus = 0,
            denom_bonus = 0,
            xl_denom = 0,
            special = explore,
        },
    },
}

return ashenzari
