-- Okawaru prefers an equipment gift when that source gate succeeds;
-- otherwise a separate Throwing check may yield one missile stack.
local channels = require("constants.message_channels")
local classes = require("ids.object_classes")
local gods = require("constants.gods")
local martial = require("policy.religion.gifts.martial")
local streams = require("constants.rng_streams")

local okawaru = {}

-- Source random_choose_weighted gives weapon and armour equal weight
-- whenever equipment is due. Missiles are considered only when it is not.
local function class_for(ctx, worship)
    if martial.equipment_due(ctx, worship) then
        if ctx:random(streams.RELIGION, 2) == 0 then
            return classes.OBJ_WEAPONS
        end

        return classes.OBJ_ARMOUR
    end

    if martial.missiles_due(ctx, worship) then
        return classes.OBJ_MISSILES
    end

    return nil
end

-- Example: a high-Throwing worshipper can receive javelins on a normal
-- floor; the same candidate on lava grants nothing and draws no gift RNG.
function okawaru.check(ctx, player, worship)
    if not martial.eligible(ctx, player) then
        return false
    end

    local class_id = class_for(ctx, worship)

    if not class_id then
        return false
    end

    local message = "Okawaru grants you a weapon!"

    if class_id == classes.OBJ_ARMOUR then
        message = "Okawaru grants you armour!"
    elseif class_id == classes.OBJ_MISSILES then
        message = "Okawaru grants you throwing weapons!"
    end

    ctx:emit(channels.RELIGION, message)

    if not martial.grant(ctx, player, class_id, gods.OKAWARU) then
        ctx:emit(channels.RELIGION, "...but nothing appears.")

        return false
    end

    return true
end

return okawaru
