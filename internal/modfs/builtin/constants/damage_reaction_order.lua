-- Surviving HP damage triggers these reactions in source order so safety runs first.

-- Source: ouch.cc:ouch runs these reactions after surviving HP damage.
local order = {
    READ_SAFETY = 10,
    DRINK_SAFETY = 20,
    DETERIORATION = 10,
    DEMONIC_GUARDIAN = 15,
    POWERED_BY_PAIN = 20,
}

return order
