-- Penance and departure revoke Elyvilon's active resource grant at once.
-- The saved timer still expires normally while worship continues.
local vigour = require("policy.religion.elyvilon.vigour")

local elyvilon = {}

-- Excommunication and voluntary renunciation use the same cleanup.
function elyvilon.leave(ctx, player)
    vigour.clear(ctx, player)
end

-- Source penance also removes the bonus before the next player action.
function elyvilon.on_penance(ctx, player)
    vigour.clear(ctx, player)
end

return elyvilon
