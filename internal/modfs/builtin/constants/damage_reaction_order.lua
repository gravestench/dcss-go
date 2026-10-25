-- Surviving HP damage triggers these reactions in source order so safety runs first.

-- Source: ouch.cc:ouch runs these reactions after surviving HP damage.
local order = {
    READ_SAFETY = 10,
    DRINK_SAFETY = 20,
    DETERIORATION = 10,
    RU_RETALIATION = 11,
    JIYVA_SLIME_EJECTION = 12,
    XOM_BUTTERFLY_EJECTION = 13,
    DEMONIC_GUARDIAN = 15,
    HIT_FOG = 17,
    POWERED_BY_PAIN = 20,
    SANGUINE_ARMOUR = 25,
    ARTEFACT_CORRODE = 30,
    ARTEFACT_SLOW = 31,
}

return order
