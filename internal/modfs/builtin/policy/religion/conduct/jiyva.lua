-- Jiyva's source conduct rewards exploration outside Slime and protects
-- true slimes from attacks. A shapeshifter posing as a slime is excluded;
-- its live identity is supplied by the combat classification owner.
local common = require("policy.religion.conduct.common")
local kinds = require("constants.religion_conduct")

-- Only actual non-shapeshifting slime deaths or attacks matter to Jiyva.
local function real_slime(_, _, event)
    return event.slime == true and event.shapeshifter ~= true
end

-- Exploration offers 26 units to a source 2500-unit pulse.
local function explore(_, _, _, _, denominator)
    return 26, denominator
end

local jiyva = {
    likes = {
        [kinds.EXPLORATION] = {
            description = "you explore the world outside of the Slime Pits",
            bonus = 0,
            denom_bonus = 0,
            xl_denom = 0,
            special = explore,
        },
    },

    dislikes = {
        [kinds.KILL_SLIME] = common.peeve(
            "you kill slimes", 1, 2, nil, real_slime),

        [kinds.ATTACK_NEUTRAL] = common.peeve(
            nil, 1, 1, nil, real_slime),

        [kinds.ATTACK_FRIEND] = common.attack_friend(
            "you attack fellow slimes", common.slime_friend),
    },
}

return jiyva
