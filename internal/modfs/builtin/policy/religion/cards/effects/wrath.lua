-- Wrath delegates source god selection and retribution to the reusable
-- religion owner. Card play itself only supplies the fallback message.
local retribution = require("policy.religion.wrath.retribution")

local wrath = {}

-- A hundred declined gods leave the card spent but spare the player.
function wrath.apply(ctx, player)
    if not retribution.sample(ctx, player) then
        ctx:emit("religion",
            "You somehow manage to escape divine attention...")
    end
end

return wrath
