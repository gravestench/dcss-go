-- Fedhas rewards ordinary kills, but living-kill piety omits player XL.
-- A plant's destruction is an offense, while attacks on disliked allies
-- use the same source pardon as other gods.
local common = require("policy.religion.conduct.common")
local kinds = require("constants.religion_conduct")

local likes = common.kills()

likes[kinds.KILL_LIVING].xl_denom = 0
likes[kinds.KILL_LIVING].message = nil

-- Source phrasing reflects whether a living victim can nourish the floor
-- through a corpse. It does not depend on the random corpse-drop outcome.
local function ecosystem(_, _, event, numerator, denominator)
    if event.leaves_corpse then
        return numerator, denominator,
            " appreciates your contribution to the ecosystem."
    end

    return numerator, denominator, " accepts your kill."
end

likes[kinds.KILL_LIVING].special = ecosystem

local fedhas = {
    likes = likes,

    dislikes = {
        [kinds.KILL_PLANT] = common.peeve(
            "you destroy plants", 1, 0),

        [kinds.ATTACK_FRIEND] = common.attack_friend(
            nil, common.plant_friend),
    },
}

return fedhas
