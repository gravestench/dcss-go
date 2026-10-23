-- Wraith is a punishment card: it drains current maximum health through
-- the same saved status used by ordinary draining attacks. The quarter-
-- power conversion comes from the source card effect, not from combat.
local drain = require("policy.combat.player_drain")
local streams = require("constants.rng_streams")

local wraith = {}

-- XP recovery remains owned by the common drain system because this card
-- creates no Wraith-specific permanent health change.
function wraith.apply(ctx, player, request)
    local strength = math.floor(request.power / 4)

    drain.apply(ctx, player, strength, streams.CARDS)
end

return wraith
