-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-zap.cc
-- SHA-256: fd04e4885288d63e576eb974d157fd3721681a0f51d393acc52fcf2bd129b83f
-- spell_to_zap uses the first listed pair for each spell.
local catalog = {
    SPELL_AGONY = {
        -- spl-zap.cc:36
        {
            zap_id = "ZAP_AGONY",
        },
    },
    SPELL_BECKONING = {
        -- spl-zap.cc:59
        {
            zap_id = "ZAP_BECKONING",
        },
    },
    SPELL_BOLT_OF_LIGHT = {
        -- spl-zap.cc:74
        {
            zap_id = "ZAP_BOLT_OF_LIGHT",
        },
    },
    SPELL_BORGNJORS_VILE_CLUTCH = {
        -- spl-zap.cc:64
        {
            zap_id = "ZAP_VILE_CLUTCH",
        },
        -- spl-zap.cc:132
        {
            zap_id = "ZAP_VILE_CLUTCH",
        },
    },
    SPELL_CHAIN_LIGHTNING = {
        -- spl-zap.cc:27
        {
            zap_id = "ZAP_CHAIN_LIGHTNING",
        },
    },
    SPELL_CHARMING = {
        -- spl-zap.cc:43
        {
            zap_id = "ZAP_CHARMING",
        },
    },
    SPELL_CORROSIVE_BOLT = {
        -- spl-zap.cc:58
        {
            zap_id = "ZAP_CORROSIVE_BOLT",
        },
    },
    SPELL_DIG = {
        -- spl-zap.cc:55
        {
            zap_id = "ZAP_DIG",
        },
    },
    SPELL_DISPEL_UNDEAD = {
        -- spl-zap.cc:35
        {
            zap_id = "ZAP_DISPEL_UNDEAD",
        },
    },
    SPELL_ENFEEBLE = {
        -- spl-zap.cc:72
        {
            zap_id = "ZAP_ENFEEBLE",
        },
    },
    SPELL_FASTROOT = {
        -- spl-zap.cc:75
        {
            zap_id = "ZAP_FASTROOT",
        },
    },
    SPELL_FIREBALL = {
        -- spl-zap.cc:32
        {
            zap_id = "ZAP_FIREBALL",
        },
    },
    SPELL_FIRE_STORM = {
        -- spl-zap.cc:67
        {
            zap_id = "ZAP_FIRE_STORM",
        },
    },
    SPELL_FLAME_WAVE = {
        -- spl-zap.cc:71
        {
            zap_id = "ZAP_FLAME_WAVE",
        },
    },
    SPELL_FOXFIRE = {
        -- spl-zap.cc:133
        {
            zap_id = "ZAP_FOXFIRE",
        },
    },
    SPELL_HAILSTORM = {
        -- spl-zap.cc:69
        {
            zap_id = "ZAP_HAILSTORM",
        },
    },
    SPELL_HIBERNATION = {
        -- spl-zap.cc:47
        {
            zap_id = "ZAP_HIBERNATION",
        },
    },
    SPELL_HURL_DAMNATION = {
        -- spl-zap.cc:42
        {
            zap_id = "ZAP_HURL_DAMNATION",
        },
    },
    SPELL_ICEBLAST = {
        -- spl-zap.cc:130
        {
            zap_id = "ZAP_ICEBLAST",
        },
    },
    SPELL_IGNITION = {
        -- spl-zap.cc:66
        {
            zap_id = "ZAP_IGNITION",
        },
    },
    SPELL_INNER_FLAME = {
        -- spl-zap.cc:53
        {
            zap_id = "ZAP_INNER_FLAME",
        },
    },
    SPELL_IRON_SHOT = {
        -- spl-zap.cc:25
        {
            zap_id = "ZAP_IRON_SHOT",
        },
    },
    SPELL_ISKENDERUNS_MYSTIC_BLAST = {
        -- spl-zap.cc:70
        {
            zap_id = "ZAP_MYSTIC_BLAST",
        },
    },
    SPELL_LEHUDIBS_CRYSTAL_SPEAR = {
        -- spl-zap.cc:31
        {
            zap_id = "ZAP_LEHUDIBS_CRYSTAL_SPEAR",
        },
    },
    SPELL_LIGHTNING_BOLT = {
        -- spl-zap.cc:26
        {
            zap_id = "ZAP_LIGHTNING_BOLT",
        },
    },
    SPELL_MAGIC_DART = {
        -- spl-zap.cc:11
        {
            zap_id = "ZAP_MAGIC_DART",
        },
    },
    SPELL_MEPHITIC_CLOUD = {
        -- spl-zap.cc:33
        {
            zap_id = "ZAP_MEPHITIC",
        },
    },
    SPELL_MINDBURST = {
        -- spl-zap.cc:37
        {
            zap_id = "ZAP_MINDBURST",
        },
    },
    SPELL_NECROTISE = {
        -- spl-zap.cc:73
        {
            zap_id = "ZAP_NECROTISE",
        },
    },
    SPELL_OZOCUBUS_REFRIGERATION = {
        -- spl-zap.cc:61
        {
            zap_id = "ZAP_REFRIGERATE",
        },
    },
    SPELL_PARALYSE = {
        -- spl-zap.cc:49
        {
            zap_id = "ZAP_PARALYSE",
        },
    },
    SPELL_PETRIFY = {
        -- spl-zap.cc:50
        {
            zap_id = "ZAP_PETRIFY",
        },
    },
    SPELL_POLYMORPH = {
        -- spl-zap.cc:51
        {
            zap_id = "ZAP_POLYMORPH",
        },
    },
    SPELL_QUICKSILVER_BOLT = {
        -- spl-zap.cc:122
        {
            zap_id = "ZAP_QUICKSILVER_BOLT",
        },
        -- spl-zap.cc:123
        {
            zap_id = "ZAP_BREATHE_POWER",
        },
    },
    SPELL_SANDBLAST = {
        -- spl-zap.cc:22
        {
            zap_id = "ZAP_SANDBLAST",
        },
    },
    SPELL_SEARING_RAY = {
        -- spl-zap.cc:68
        {
            zap_id = "ZAP_SEARING_RAY",
        },
    },
    SPELL_SHOCK = {
        -- spl-zap.cc:17
        {
            zap_id = "ZAP_SHOCK",
        },
    },
    SPELL_SLOW = {
        -- spl-zap.cc:45
        {
            zap_id = "ZAP_SLOW",
        },
    },
    SPELL_SONIC_WAVE = {
        -- spl-zap.cc:63
        {
            zap_id = "ZAP_SONIC_WAVE",
        },
    },
    SPELL_STARBURST = {
        -- spl-zap.cc:65
        {
            zap_id = "ZAP_BOLT_OF_FIRE",
        },
    },
    SPELL_STICKY_FLAME = {
        -- spl-zap.cc:124
        {
            zap_id = "ZAP_STICKY_FLAME",
        },
    },
    SPELL_STING = {
        -- spl-zap.cc:18
        {
            zap_id = "ZAP_STING",
        },
    },
    SPELL_STONE_ARROW = {
        -- spl-zap.cc:23
        {
            zap_id = "ZAP_STONE_ARROW",
        },
    },
    SPELL_TELEPORT_OTHER = {
        -- spl-zap.cc:52
        {
            zap_id = "ZAP_TELEPORT_OTHER",
        },
    },
    SPELL_THROW_FLAME = {
        -- spl-zap.cc:13
        {
            zap_id = "ZAP_THROW_FLAME",
        },
    },
    SPELL_TUKIMAS_DANCE = {
        -- spl-zap.cc:57
        {
            zap_id = "ZAP_TUKIMAS_DANCE",
        },
    },
    SPELL_VAMPIRIC_DRAINING = {
        -- spl-zap.cc:39
        {
            zap_id = "ZAP_VAMPIRIC_DRAINING",
        },
    },
    SPELL_VIOLENT_UNRAVELLING = {
        -- spl-zap.cc:34
        {
            zap_id = "ZAP_UNRAVELLING",
        },
    },
}

return catalog
