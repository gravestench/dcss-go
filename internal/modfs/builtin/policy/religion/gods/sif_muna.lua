-- Leaving Sif or entering penance removes Channel Magic at the transition,
-- instead of waiting for the next player action to discover stale worship.
local channel = require("policy.religion.sif_muna.channel")

local sif_muna = {}

-- Renunciation and conversion share the same one-time cleanup.
function sif_muna.leave(ctx, player)
    channel.clear(ctx, player)
end

-- Penance revokes the granted MP flow immediately.
function sif_muna.on_penance(ctx, player)
    channel.clear(ctx, player)
end

return sif_muna
