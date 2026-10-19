-- Damage cause distinguishes direct hits from poison, clouds, and other delayed sources.

local damage_causes = {
    ORDINARY = "ordinary",
    POISON = "poison",
    FLAY = "flay",
    INJURY_BOND = "injury_bond",
    HIT = "hit",
    CLOUD = "cloud",
    REFLECTED = "reflected",
}

return damage_causes
