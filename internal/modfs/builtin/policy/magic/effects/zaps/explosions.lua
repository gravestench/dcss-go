local spells = require("ids.spells")
local explosive = require("policy.magic.effects.zaps.explosive")

local explosions = {}

-- zap-data.h player-side calcdice; spl-cast.cc targeter_beam uses radius one.
explosions.fireball = {
    name = "fireball",
    cap = 200,
    element = "MR_RES_FIRE",
    damage = {
        count = 3,
        base = 10,
        numerator = 1,
        denominator = 2,
    },
}

explosions.iceblast = {
    name = "iceblast",
    cap = 200,
    element = "MR_RES_COLD",
    resistible_fraction = 40,
    damage = {
        count = 3,
        base = 14,
        numerator = 3,
        denominator = 5,
    },
}

explosions.hurl_damnation = {
    name = "sphere of damnation",
    cap = 200,
    element = "MR_RES_DAMNATION",
    ac_rule = "none",
    damage = {
        count = 3,
        base = 8,
        numerator = 3,
        denominator = 5,
    },
}

explosive.register(spells.SPELL_FIREBALL, explosions.fireball)
explosive.register(spells.SPELL_ICEBLAST, explosions.iceblast)
explosive.register(spells.SPELL_HURL_DAMNATION, explosions.hurl_damnation)

return explosions
