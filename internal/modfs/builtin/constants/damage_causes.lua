-- Damage cause distinguishes direct hits from poison, clouds, and other delayed sources.

local damage_causes = {
    ORDINARY = "ordinary",
    POISON = "poison",
    FLAY = "flay",
    HIT = "hit",
    CLOUD = "cloud",
    REFLECTED = "reflected",
}

return damage_causes
