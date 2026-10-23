-- Trog's martial reward is always a weapon. The shared equipment gate
-- keeps its timing identical to Okawaru's without a common god switch.
local channels = require("constants.message_channels")
local classes = require("ids.object_classes")
local gods = require("constants.gods")
local martial = require("policy.religion.gifts.martial")

local trog = {}

-- Example: a high-piety worshipper may find a Trog-marked weapon at their
-- feet; a failed gate or unusable floor consumes no gift count.
function trog.check(ctx, player, worship)
    if not martial.eligible(ctx, player) or
        not martial.equipment_due(ctx, worship) then
        return false
    end

    ctx:emit(channels.RELIGION, "Trog grants you a weapon!")

    if not martial.grant(ctx, player, classes.OBJ_WEAPONS,
        gods.TROG) then
        ctx:emit(channels.RELIGION, "...but nothing appears.")

        return false
    end

    return true
end

return trog
