-- Damage cause distinguishes direct hits from poison, clouds, and other delayed sources.

local damage_causes = {
    ORDINARY = "ordinary",
    POISON = "poison",
    FLAY = "flay",
    INJURY_BOND = "injury_bond",
    HIT = "hit",
    BEAM = "beam",
    BLAST = "blast",
    CLOUD = "cloud",
    WATER = "water",
    ACID = "acid",
    REFLECTED = "reflected",
}

return damage_causes
