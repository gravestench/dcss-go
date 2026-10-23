-- Yredelemnul has no ordinary kill-piety response in this source matrix.
-- Holy item or magic use is the relevant conduct offense; immediate wrath
-- after a surviving offense belongs to this god's later wrath handler.
local common = require("policy.religion.conduct.common")
local kinds = require("constants.religion_conduct")

local yredelemnul = {
    dislikes = {
        [kinds.HOLY] = common.peeve(
            "you use holy magic or items", 1, 2,
            " forgives your inadvertent holy act, just this once."),
    },
}

return yredelemnul
