-- Ru uses exploration to move the saved sacrifice-offer clock, not to
-- award ordinary piety. The offer itself is owned by Ru's later ability
-- domain; this conduct only records source progress.
local component = require("constants.component")
local kinds = require("constants.religion_conduct")
local streams = require("constants.rng_streams")

-- One in a hundred exploration pulses advances the next sacrifice offer.
local function explore(ctx, player)
    local state = ctx:get(player, component.RELIGION_RU)

    if not state then
        error("Ru conduct requires saved sacrifice state")
    end

    if ctx:random(streams.RELIGION, 100) == 0 then
        state.sacrifice_progress = state.sacrifice_progress + 1
        ctx:set(player, component.RELIGION_RU, state)
    end

    return 0, 1
end

local ru = {
    likes = {
        [kinds.EXPLORATION] = {
            bonus = 0,
            denom_bonus = 0,
            xl_denom = 0,
            special = explore,
        },
    },
}

return ru
