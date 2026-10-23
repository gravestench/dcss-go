-- An overlay with a negative loss factor must fail before gameplay.
local kinds = require("constants.religion_conduct")

local zin = {
    dislikes = {
        [kinds.EVIL] = {
            loss_factor = -1,
            penance_factor = 1,
        },
    },
}

return zin
