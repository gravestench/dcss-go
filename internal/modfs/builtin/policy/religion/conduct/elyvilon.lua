-- Elyvilon gains devotion from exploration rather than kills. The same
-- good-god protections against evil and harmed allies remain active.
local common = require("policy.religion.conduct.common")
local kinds = require("constants.religion_conduct")

-- Each source exploration pulse has severity 2500; only twenty units are
-- offered as numerator, so most pulses do not award a point.
local function explore(_, _, _, _, denominator)
    return 20, denominator
end

local elyvilon = {
    likes = {
        [kinds.EXPLORATION] = {
            description = "you explore the world",
            bonus = 0,
            denom_bonus = 0,
            xl_denom = 0,
            special = explore,
        },
    },

    dislikes = {
        [kinds.ATTACK_HOLY] = common.peeve(
            "you attack non-hostile holy beings", 1, 1,
            nil, common.holy_matters),

        [kinds.KILL_HOLY] = common.kill_holy_peeve(),

        [kinds.EVIL] = common.peeve(
            "you use evil magic or items", 1, 1,
            " forgives your inadvertent evil act, just this once."),

        [kinds.ATTACK_NEUTRAL] = common.peeve(
            "you attack neutral beings", 1, 1,
            " forgives your inadvertent attack on a neutral, just this once."),

        [kinds.ATTACK_FRIEND] = common.attack_friend(
            "you attack allies"),
    },
}

return elyvilon
