-- Missile brands add a projectile effect after the base missile hit resolves.

-- Source: mon-gear.cc Kobold ammunition special case.
local brands = {
    POISONED = "poisoned",
    CURARE = "curare",
    BLINDING = "blinding",
    FRENZY = "frenzy",
    -- Source DES names the two dart coatings, while the engine stores
    -- their effect brands. Both spellings must resolve to one saved ego.
    ATROPA = "blinding",
    DATURA = "frenzy",
    SILVER = "silver",
    DISPERSAL = "dispersal",
}

return brands
