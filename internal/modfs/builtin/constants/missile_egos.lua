-- Missile ego IDs belong to the thrown item's saved state. A launcher uses
-- weapon brand IDs instead, so its ego is intentionally a separate namespace.
local egos = {
    BLINDING = "blinding",
    CHAOS = "chaos",
    CURARE = "curare",
    DISPERSAL = "dispersal",
    EXPLODING = "exploding",
    FLAME = "flame",
    FRENZY = "frenzy",
    FROST = "frost",
    POISONED = "poisoned",
    SILVER = "silver",
    -- DES calls the two dart coatings by name; saves use their effect IDs.
    ATROPA = "blinding",
    DATURA = "frenzy",
}

return egos
