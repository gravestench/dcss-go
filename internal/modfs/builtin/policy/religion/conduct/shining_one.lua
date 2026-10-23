-- The Shining One rewards vanquishing evil and seeing other hostile foes.
-- It also protects friendly, neutral, and formerly neutral holy creatures;
-- these distinctions are classified before combat mutates attitude.
local common = require("policy.religion.conduct.common")
local kinds = require("constants.religion_conduct")
local component = require("constants.component")

-- Seeing a creature that already earns kill piety gives no encounter
-- reward. This source gate runs before any religion RNG is consumed.
local function unseen_evil(_, _, event)
    return event.evil ~= true
end

-- Source denominator is based on monster HD and player XL; the numerator
-- stays four below it. This rewards dangerous first encounters more often.
local function encounter(ctx, player, event)
    local progress = ctx:get(player, component.PROGRESSION)

    if not progress then
        error("encounter conduct requires player progression")
    end

    local denominator = math.floor(event.level / 2) + 6 -
        math.floor(progress.level / 4)

    return denominator - 4, denominator
end

local shining_one = {
    likes = {
        [kinds.KILL_UNDEAD] = common.kill(
            "you kill the undead", -5, true),

        [kinds.KILL_DEMON] = common.kill(
            "you kill demons", -4, true),

        [kinds.KILL_NATURAL_EVIL] = common.kill(
            "you kill evil beings", -4, true),

        [kinds.SEE_MONSTER] = {
            description = "you encounter other hostile creatures",
            bonus = 0,
            denom_bonus = 0,
            xl_denom = 0,
            filter = unseen_evil,
            special = encounter,
        },
    },

    dislikes = {
        [kinds.ATTACK_HOLY] = common.peeve(
            "you attack non-hostile holy beings", 1, 2,
            nil, common.holy_matters),

        [kinds.KILL_HOLY] = common.kill_holy_peeve(),

        [kinds.EVIL] = common.peeve(
            "you use evil magic or items", 1, 2,
            " forgives your inadvertent evil act, just this once."),

        [kinds.ATTACK_NEUTRAL] = common.peeve(
            "you attack neutral beings", 1, 1,
            " forgives your inadvertent attack on a neutral, just this once."),

        [kinds.ATTACK_FRIEND] = common.attack_friend(
            "you attack allies"),
    },
}

return shining_one
