-- Source: melee-attack.cc:aux_attack_types. Sparse order values leave room
-- for a modded attack to enter between source attack types.
local attacks = {
    CONSTRICT = { id = "constrict", order = 10 },
    KICK = { id = "kick", order = 20 },
    HEADBUTT = { id = "headbutt", order = 30 },
    PECK = { id = "peck", order = 40 },
    TAILSLAP = { id = "tail-slap", order = 50 },
    TOUCH = { id = "touch", order = 60 },
    PUNCH = { id = "punch", order = 70 },
    BITE = { id = "bite", order = 80 },
    PSEUDOPODS = { id = "pseudopods", order = 90 },
    TENTACLES = { id = "tentacles", order = 100 },
}

return attacks
