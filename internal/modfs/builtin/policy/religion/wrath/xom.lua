-- Xom's divine retribution uses the same live action owner as worship.
-- Only the one-in-ten nice override and the card RNG stream belong here.
local actions = require("policy.religion.xom.actions")
local streams = require("constants.rng_streams")
local xom = {}

-- The card's source wrath chooses niceness before severity, tension, and
-- selection. The retribution owner handles penance and bonus aftermath.
function xom.apply(ctx, player)
    local nice = ctx:random(streams.CARDS, 10) == 0

    actions.act(ctx, player, {
        nice = nice,
        stream = streams.CARDS,
    })

    return true
end

return xom
