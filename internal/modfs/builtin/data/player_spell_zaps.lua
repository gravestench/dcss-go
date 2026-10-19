-- Spell-to-zap rows map an authored player spell onto a beam or effect definition.

-- Source: crawl-ref/source/spl-zap.cc
-- SHA-256: fd04e4885288d63e576eb974d157fd3721681a0f51d393acc52fcf2bd129b83f
-- spell_to_zap uses the first listed pair for each spell.
local catalog = {
    SPELL_AGONY = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_AGONY",
        },
    },
    SPELL_BECKONING = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_BECKONING",
        },
    },
    SPELL_BOLT_OF_LIGHT = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_BOLT_OF_LIGHT",
        },
    },
    SPELL_BORGNJORS_VILE_CLUTCH = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_VILE_CLUTCH",
        },
        -- spl-zap.cc
        {
            zap_id = "ZAP_VILE_CLUTCH",
        },
    },
    SPELL_CHAIN_LIGHTNING = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_CHAIN_LIGHTNING",
        },
    },
    SPELL_CHARMING = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_CHARMING",
        },
    },
    SPELL_CORROSIVE_BOLT = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_CORROSIVE_BOLT",
        },
    },
    SPELL_DIG = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_DIG",
        },
    },
    SPELL_DISPEL_UNDEAD = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_DISPEL_UNDEAD",
        },
    },
    SPELL_ENFEEBLE = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_ENFEEBLE",
        },
    },
    SPELL_FASTROOT = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_FASTROOT",
        },
    },
    SPELL_FIREBALL = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_FIREBALL",
        },
    },
    SPELL_FIRE_STORM = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_FIRE_STORM",
        },
    },
    SPELL_FLAME_WAVE = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_FLAME_WAVE",
        },
    },
    SPELL_FOXFIRE = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_FOXFIRE",
        },
    },
    SPELL_HAILSTORM = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_HAILSTORM",
        },
    },
    SPELL_HIBERNATION = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_HIBERNATION",
        },
    },
    SPELL_HURL_DAMNATION = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_HURL_DAMNATION",
        },
    },
    SPELL_ICEBLAST = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_ICEBLAST",
        },
    },
    SPELL_IGNITION = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_IGNITION",
        },
    },
    SPELL_INNER_FLAME = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_INNER_FLAME",
        },
    },
    SPELL_IRON_SHOT = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_IRON_SHOT",
        },
    },
    SPELL_ISKENDERUNS_MYSTIC_BLAST = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_MYSTIC_BLAST",
        },
    },
    SPELL_LEHUDIBS_CRYSTAL_SPEAR = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_LEHUDIBS_CRYSTAL_SPEAR",
        },
    },
    SPELL_LIGHTNING_BOLT = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_LIGHTNING_BOLT",
        },
    },
    SPELL_MAGIC_DART = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_MAGIC_DART",
        },
    },
    SPELL_MEPHITIC_CLOUD = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_MEPHITIC",
        },
    },
    SPELL_MINDBURST = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_MINDBURST",
        },
    },
    SPELL_NECROTISE = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_NECROTISE",
        },
    },
    SPELL_OZOCUBUS_REFRIGERATION = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_REFRIGERATE",
        },
    },
    SPELL_PARALYSE = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_PARALYSE",
        },
    },
    SPELL_PETRIFY = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_PETRIFY",
        },
    },
    SPELL_POLYMORPH = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_POLYMORPH",
        },
    },
    SPELL_QUICKSILVER_BOLT = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_QUICKSILVER_BOLT",
        },
        -- spl-zap.cc
        {
            zap_id = "ZAP_BREATHE_POWER",
        },
    },
    SPELL_SANDBLAST = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_SANDBLAST",
        },
    },
    SPELL_SEARING_RAY = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_SEARING_RAY",
        },
    },
    SPELL_SHOCK = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_SHOCK",
        },
    },
    SPELL_SLOW = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_SLOW",
        },
    },
    SPELL_SONIC_WAVE = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_SONIC_WAVE",
        },
    },
    SPELL_STARBURST = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_BOLT_OF_FIRE",
        },
    },
    SPELL_STICKY_FLAME = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_STICKY_FLAME",
        },
    },
    SPELL_STING = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_STING",
        },
    },
    SPELL_STONE_ARROW = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_STONE_ARROW",
        },
    },
    SPELL_TELEPORT_OTHER = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_TELEPORT_OTHER",
        },
    },
    SPELL_THROW_FLAME = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_THROW_FLAME",
        },
    },
    SPELL_TUKIMAS_DANCE = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_TUKIMAS_DANCE",
        },
    },
    SPELL_VAMPIRIC_DRAINING = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_VAMPIRIC_DRAINING",
        },
    },
    SPELL_VIOLENT_UNRAVELLING = {
        -- spl-zap.cc
        {
            zap_id = "ZAP_UNRAVELLING",
        },
    },
}

return catalog
