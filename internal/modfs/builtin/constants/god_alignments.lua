-- Source god alignment is shared by retribution and monster protection.
-- It describes intrinsic patron policy, independent of a worshipper's
-- current piety or a particular god's behavior module.
local gods = require("constants.gods")

local alignments = {
    GOOD = {
        [gods.ZIN] = true,
        [gods.SHINING_ONE] = true,
        [gods.ELYVILON] = true,
    },

    CHAOTIC = {
        [gods.XOM] = true,
        [gods.MAKHLEB] = true,
        [gods.LUGONU] = true,
        [gods.JIYVA] = true,
    },
}

return alignments
