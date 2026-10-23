-- Cheibriados punishes haste but appreciates the death of foes faster than
-- the player. The speed comparison and chance to double appreciation are
-- specific to this god, not to the common kill curve.
local common = require("policy.religion.conduct.common")
local kinds = require("constants.religion_conduct")

-- Source chance is speed delta out of twelve. A large delta always
-- doubles the offered piety, while a near tie rarely does.
local function pace(ctx, _, event, numerator, denominator)
    if type(event.speed_delta) ~= "number" then
        error("Cheibriados kill requires relative speed")
    end

    if event.speed_delta > 0 and
        ctx:random("religion", 12) < event.speed_delta then
        return numerator * 2, denominator,
            " thoroughly appreciates the change of pace."
    end

    return numerator, denominator,
        " appreciates the change of pace."
end

local fast_kill = common.kill(
    "you kill fast things, relative to your speed", -6)

fast_kill.message = nil
fast_kill.special = pace

local cheibriados = {
    likes = {
        [kinds.KILL_FAST] = fast_kill,
    },

    dislikes = {
        [kinds.HASTY] = {
            description = "you hasten yourself or others",
            loss_factor = 1,
            penance_factor = 1,
            penance_offset = -5,
            forgiveness = " forgives your accidental hurry, just this once.",
            message = " thinks you should slow down.",
        },
    },
}

return cheibriados
