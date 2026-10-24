-- Joining Xom at an ecumenical altar stimulates him immediately. Interest
-- lives in the normal saved worship record, so no pending side component
-- can survive conversion without ever changing play.
local stimulation = require("policy.religion.xom.stimulation")

local xom = {}

-- The altar supplies source interestingness 200 after Xom's initial mood
-- and interest draws. The shared stimulation owner performs the final roll.
function xom.ecumenical_bonus(ctx, player)
    stimulation.apply(ctx, player, 200)
end

return xom
