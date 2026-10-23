-- Beogh uses the ordinary kill curve and adds a second chance for killing
-- another faith's priest. Allied-orc attacks and corpse desecration are
-- separate peeves, so a future corpse action can report its own event.
local common = require("policy.religion.conduct.common")
local kinds = require("constants.religion_conduct")

local likes = common.kills()

likes[kinds.KILL_PRIEST] = {
    description = "you kill the priests of other religions",
    bonus = -6,
    denom_bonus = 18,
    xl_denom = 0,
    message = " appreciates your killing of a heretic priest.",
}

local beogh = {
    likes = likes,

    dislikes = {
        [kinds.DESECRATE_ORCISH_REMAINS] = common.peeve(
            "you desecrate orcish remains", 1, 0),

        [kinds.ATTACK_FRIEND] = common.attack_friend(
            "you attack allied orcs", common.orc_friend),
    },
}

return beogh
