-- General reading checks from item-use.cc:cannot_read_item_reason.
local confusion = require("policy.magic.player_confusion")
local damage_safety = require("policy.character.damage_safety")
local engulf = require("policy.combat.engulf")
local rage = require("policy.character.rage")
local safety_restrictions = require("constants.safety_restrictions")
local silence = require("policy.world.silence")

local restrictions = {}

-- Example: silence prevents reading a magic scroll before its effect or target menu runs.
-- Check rage, confusion, and silence before an effect can open a menu or consume its scroll.
function restrictions.reason(ctx, player)
    if rage.active(ctx, player) then
        return "You are too berserk!"
    end

    if confusion.active(ctx, player) then
        return "You are too confused!"
    end

    if damage_safety.active(ctx, player, safety_restrictions.SCROLLS) then
        return "You cannot read scrolls in your current state!"
    end

    if silence.actor(ctx, player) then
        return "Magic scrolls do not work when you're silenced!"
    end

    if engulf.silenced(ctx, player) then
        return "You cannot read scrolls while unable to breathe!"
    end

    return nil
end

return restrictions
