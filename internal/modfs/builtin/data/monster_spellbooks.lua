-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/externs.h
-- Source: crawl-ref/source/mon-mst.h
-- Source: crawl-ref/source/mon-spell.h

return {
    schema_version = 2,
    source_revision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f",
    source_files = {
        {
            path = "crawl-ref/source/externs.h",
            sha256 = "6a1f394df9a93e6a411680a1ca6a69524bc29259c16cc2e9850ee0aac168a211",
        },
        {
            path = "crawl-ref/source/mon-mst.h",
            sha256 = "d73ad1c8ad8fbd4c82a1f56847c193ffbdd41f617f1b77f98969a1e4fe98f800",
        },
        {
            path = "crawl-ref/source/mon-spell.h",
            sha256 = "ee46cb6314b5464dd617975eb064e271af3448ed4494486d3de3b2c7fef84021",
        },
    },
    books = {
        {
            id = "MST_BLINKER",
            source_line = 31,
            slots = {
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 33,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_BATTLECRY",
            source_line = 38,
            slots = {
                {
                    spell_id = "SPELL_BATTLECRY",
                    source_line = 40,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
            },
        },
        {
            id = "MST_DRAIN_GAZE",
            source_line = 45,
            slots = {
                {
                    spell_id = "SPELL_DRAINING_GAZE",
                    source_line = 47,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_INSTANT",
                    },
                },
            },
        },
        {
            id = "MST_ZAPPER",
            source_line = 52,
            slots = {
                {
                    spell_id = "SPELL_ELECTRICAL_BOLT",
                    source_line = 54,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_ACID_SPIT",
            source_line = 59,
            slots = {
                {
                    spell_id = "SPELL_SPIT_ACID",
                    source_line = 61,
                    frequency = 67,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_SPLINTER_BREATH",
            source_line = 66,
            slots = {
                {
                    spell_id = "SPELL_METAL_SPLINTERS",
                    source_line = 68,
                    frequency = 68,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_SCREAMER",
            source_line = 74,
            slots = {
                {
                    spell_id = "SPELL_WARNING_CRY",
                    source_line = 76,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_VOCAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_ANNIHILATOR",
            source_line = 81,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 83,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_POISON_ARROW",
                    source_line = 84,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 85,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
                    source_line = 86,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 87,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_ENTROPY_WEAVER",
            source_line = 92,
            slots = {
                {
                    spell_id = "SPELL_ENTROPIC_WEAVE",
                    source_line = 94,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SHARD_SHRIKE",
            source_line = 99,
            slots = {
                {
                    spell_id = "SPELL_THROW_ICICLE",
                    source_line = 101,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_FAUN",
            source_line = 106,
            slots = {
                {
                    spell_id = "SPELL_CORONA",
                    source_line = 108,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_STRIP_WILLPOWER",
                    source_line = 109,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SATYR",
            source_line = 113,
            slots = {
                {
                    spell_id = "SPELL_BATTLECRY",
                    source_line = 115,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
                {
                    spell_id = "SPELL_CAUSE_FEAR",
                    source_line = 116,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLEEP",
                    source_line = 117,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_FIRE_MAGE",
            source_line = 122,
            slots = {
                {
                    spell_id = "SPELL_STICKY_FLAME_RANGE",
                    source_line = 124,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 125,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_FIRE_ELEMENTALS",
                    source_line = 126,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 127,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_AIR_MAGE",
            source_line = 131,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 133,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 134,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_KNIGHT",
            source_line = 138,
            slots = {
                {
                    spell_id = "SPELL_THROW_ICICLE",
                    source_line = 140,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_FORCE_LANCE",
                    source_line = 141,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 142,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 143,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_ARCHER",
            source_line = 147,
            slots = {
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 149,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 150,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_REPEL_MISSILES",
                    source_line = 151,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_AWAY",
                    source_line = 152,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_SHORT_RANGE",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_ELEMENTALIST",
            source_line = 156,
            slots = {
                {
                    spell_id = "SPELL_FREEZING_CLOUD",
                    source_line = 158,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 159,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AWAKEN_EARTH",
                    source_line = 160,
                    frequency = 44,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_REPEL_MISSILES",
                    source_line = 161,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 162,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_SORCERER",
            source_line = 166,
            slots = {
                {
                    spell_id = "SPELL_CORROSIVE_BOLT",
                    source_line = 168,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BANISHMENT",
                    source_line = 169,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 170,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HURL_DAMNATION",
                    source_line = 171,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_HIGH_PRIEST",
            source_line = 175,
            slots = {
                {
                    spell_id = "SPELL_AURA_OF_BRILLIANCE",
                    source_line = 177,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_CALL_DOWN_DAMNATION",
                    source_line = 178,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_MALIGN_OFFERING",
                    source_line = 179,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 180,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_DEMONOLOGIST",
            source_line = 184,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_DEMON",
                    source_line = 186,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_GREATER_DEMON",
                    source_line = 187,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BANISHMENT",
                    source_line = 188,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_ELF_DEATH_MAGE",
            source_line = 192,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 194,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_VAMPIRIC_DRAINING",
                    source_line = 195,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CALL_LOST_SOUL",
                    source_line = 196,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_THORN_HUNTER",
            source_line = 201,
            slots = {
                {
                    spell_id = "SPELL_THORN_VOLLEY",
                    source_line = 203,
                    frequency = 43,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_WALL_OF_BRAMBLES",
                    source_line = 204,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_DEATHCAP",
            source_line = 208,
            slots = {
                {
                    spell_id = "SPELL_DRAIN_LIFE",
                    source_line = 210,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SHAMBLING_MANGROVE",
            source_line = 214,
            slots = {
                {
                    spell_id = "SPELL_GRASPING_ROOTS",
                    source_line = 216,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_BOUDA",
            source_line = 221,
            slots = {
                {
                    spell_id = "SPELL_HEAL_OTHER",
                    source_line = 223,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_MINOR_HEALING",
                    source_line = 224,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                        "MON_SPELL_EMERGENCY",
                    },
                },
                {
                    spell_id = "SPELL_WEAKENING_GAZE",
                    source_line = 225,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                        "MON_SPELL_INSTANT",
                    },
                },
                {
                    spell_id = "SPELL_HUNTING_CALL",
                    source_line = 226,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
            },
        },
        {
            id = "MST_BOGGART",
            source_line = 230,
            slots = {
                {
                    spell_id = "SPELL_SHADOW_CREATURES",
                    source_line = 232,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 233,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 234,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_BEAR",
            source_line = 239,
            slots = {
                {
                    spell_id = "SPELL_BERSERKER_RAGE",
                    source_line = 241,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_HELL_HOUND",
            source_line = 245,
            slots = {
                {
                    spell_id = "SPELL_FIRE_BREATH",
                    source_line = 247,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_RAIJU",
            source_line = 251,
            slots = {
                {
                    spell_id = "SPELL_BLINKBOLT",
                    source_line = 253,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_HELL_HOG",
            source_line = 257,
            slots = {
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 259,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_DOOM_HOUND",
            source_line = 263,
            slots = {
                {
                    spell_id = "SPELL_DOOM_HOWL",
                    source_line = 265,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_SPRIGGAN_BERSERKER",
            source_line = 270,
            slots = {
                {
                    spell_id = "SPELL_BROTHERS_IN_ARMS",
                    source_line = 272,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_BERSERKER_RAGE",
                    source_line = 273,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_TROGS_HAND",
                    source_line = 274,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_SPRIGGAN_DRUID",
            source_line = 278,
            slots = {
                {
                    spell_id = "SPELL_STONE_ARROW",
                    source_line = 280,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_DRUIDS_CALL",
                    source_line = 281,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AWAKEN_FOREST",
                    source_line = 282,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MINOR_HEALING",
                    source_line = 283,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_SPRIGGAN_AIR_MAGE",
            source_line = 287,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 289,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AIRSTRIKE",
                    source_line = 290,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_REPEL_MISSILES",
                    source_line = 291,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_RIME_DRAKE",
            source_line = 296,
            slots = {
                {
                    spell_id = "SPELL_FLASH_FREEZE",
                    source_line = 298,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_SWAMP_DRAKE",
            source_line = 302,
            slots = {
                {
                    spell_id = "SPELL_NOXIOUS_CLOUD",
                    source_line = 304,
                    frequency = 54,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_WIND_DRAKE",
            source_line = 308,
            slots = {
                {
                    spell_id = "SPELL_WIND_BLAST",
                    source_line = 310,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_AIRSTRIKE",
                    source_line = 311,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_REPEL_MISSILES",
                    source_line = 312,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_LINDWURM",
            source_line = 316,
            slots = {
                {
                    spell_id = "SPELL_FIRE_BREATH",
                    source_line = 318,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_DEATH_DRAKE",
            source_line = 322,
            slots = {
                {
                    spell_id = "SPELL_MIASMA_BREATH",
                    source_line = 324,
                    frequency = 59,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_BASILISK",
            source_line = 329,
            slots = {
                {
                    spell_id = "SPELL_PETRIFY",
                    source_line = 331,
                    frequency = 56,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_MERFOLK_SIREN",
            source_line = 336,
            slots = {
                {
                    spell_id = "SPELL_SIREN_SONG",
                    source_line = 338,
                    frequency = 160,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_WATER_NYMPH",
            source_line = 342,
            slots = {
                {
                    spell_id = "SPELL_WATERSTRIKE",
                    source_line = 344,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_MERFOLK_AVATAR",
            source_line = 348,
            slots = {
                {
                    spell_id = "SPELL_AVATAR_SONG",
                    source_line = 350,
                    frequency = 160,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_MERFOLK_AQUAMANCER",
            source_line = 354,
            slots = {
                {
                    spell_id = "SPELL_PRIMAL_WAVE",
                    source_line = 356,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_STEAM_BALL",
                    source_line = 357,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_THROW_ICICLE",
                    source_line = 358,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 359,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_BOG_BODY",
            source_line = 364,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 366,
                    frequency = 28,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 367,
                    frequency = 28,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_ORC_PRIEST",
            source_line = 372,
            slots = {
                {
                    spell_id = "SPELL_CANTRIP",
                    source_line = 374,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_PAIN",
                    source_line = 375,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 376,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_HEAL_OTHER",
                    source_line = 377,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_ORC_WIZARD",
            source_line = 382,
            slots = {
                {
                    spell_id = "SPELL_MAGIC_DART",
                    source_line = 384,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_THROW_FLAME",
                    source_line = 385,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 386,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 387,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_ORC_KNIGHT",
            source_line = 391,
            slots = {
                {
                    spell_id = "SPELL_BATTLECRY",
                    source_line = 393,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
            },
        },
        {
            id = "MST_ORC_HIGH_PRIEST",
            source_line = 397,
            slots = {
                {
                    spell_id = "SPELL_PAIN",
                    source_line = 399,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 400,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DEMON",
                    source_line = 401,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_HEAL_OTHER",
                    source_line = 402,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_ORC_SORCERER",
            source_line = 406,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 408,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 409,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DEMON",
                    source_line = 410,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 411,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NECROMANCER",
            source_line = 416,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 418,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AGONY_RANGE",
                    source_line = 419,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BIND_SOULS",
                    source_line = 420,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_WIZARD",
            source_line = 425,
            slots = {
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 427,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BANISHMENT",
                    source_line = 428,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 429,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 430,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEATH_KNIGHT",
            source_line = 434,
            slots = {
                {
                    spell_id = "SPELL_AGONY_RANGE",
                    source_line = 436,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_INJURY_MIRROR",
                    source_line = 437,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_HELL_KNIGHT",
            source_line = 441,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 443,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 444,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_PRIEST",
                        "MON_SPELL_EMERGENCY",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 445,
                    frequency = 26,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_VAULT_SENTINEL",
            source_line = 449,
            slots = {
                {
                    spell_id = "SPELL_WARNING_CRY",
                    source_line = 451,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_VOCAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_SENTINEL_MARK",
                    source_line = 452,
                    frequency = 58,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_IRONBOUND_PRESERVER",
            source_line = 456,
            slots = {
                {
                    spell_id = "SPELL_INJURY_BOND",
                    source_line = 458,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MINOR_HEALING",
                    source_line = 459,
                    frequency = 41,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_IRONBOUND_CONVOKER",
            source_line = 463,
            slots = {
                {
                    spell_id = "SPELL_WORD_OF_RECALL",
                    source_line = 465,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MIGHT_OTHER",
                    source_line = 466,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_VAULT_WARDEN",
            source_line = 470,
            slots = {
                {
                    spell_id = "SPELL_SEAL_DOORS",
                    source_line = 472,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_IRONBOUND_FROSTHEART",
            source_line = 476,
            slots = {
                {
                    spell_id = "SPELL_CREEPING_FROST",
                    source_line = 478,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_IMPERIAL_MYRMIDON",
            source_line = 482,
            slots = {
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 484,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 485,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AGONY_RANGE",
                    source_line = 486,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SERVANT_OF_WHISPERS",
            source_line = 490,
            slots = {
                {
                    spell_id = "SPELL_STILL_WINDS",
                    source_line = 492,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 493,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_RAGGED_HIEROPHANT",
            source_line = 497,
            slots = {
                {
                    spell_id = "SPELL_INJURY_BOND",
                    source_line = 499,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_RESONANCE_STRIKE",
                    source_line = 500,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_HALAZID_WARLOCK",
            source_line = 504,
            slots = {
                {
                    spell_id = "SPELL_GHOSTLY_SACRIFICE",
                    source_line = 506,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 507,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 508,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SHADOW_CREATURES",
                    source_line = 509,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_KILLER_KLOWN",
            source_line = 513,
            slots = {
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 515,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_THROW_PIE",
                    source_line = 516,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_DRACONIAN_SCORCHER",
            source_line = 522,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 524,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_MAGMA",
                    source_line = 525,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 526,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HURL_DAMNATION",
                    source_line = 527,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CALL_DOWN_DAMNATION",
                    source_line = 528,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DRACONIAN_KNIGHT",
            source_line = 532,
            slots = {
                {
                    spell_id = "SPELL_THROW_ICICLE",
                    source_line = 534,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 535,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 536,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 537,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DRACONIAN_STORMCALLER",
            source_line = 541,
            slots = {
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 543,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DRAKES",
                    source_line = 544,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_UPHEAVAL",
                    source_line = 545,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_DRACONIAN_SHIFTER",
            source_line = 549,
            slots = {
                {
                    spell_id = "SPELL_DIMENSION_ANCHOR",
                    source_line = 551,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_OTHER",
                    source_line = 552,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_RANGE",
                    source_line = 553,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_ALLIES_ENCIRCLE",
                    source_line = 554,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_AWAY",
                    source_line = 555,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_CRYSTAL_ECHIDNA",
            source_line = 560,
            slots = {
                {
                    spell_id = "SPELL_CRYSTAL_BOLT",
                    source_line = 562,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_THROW_BARBS",
                    source_line = 563,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_JUMPING_SPIDER",
            source_line = 568,
            slots = {
                {
                    spell_id = "SPELL_BLINK_CLOSE",
                    source_line = 570,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_AWAY",
                    source_line = 571,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_ORB_SPIDER",
            source_line = 575,
            slots = {
                {
                    spell_id = "SPELL_IOOD",
                    source_line = 577,
                    frequency = 80,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_BROODMOTHER",
            source_line = 581,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_SPIDERS",
                    source_line = 583,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_CULICIVORA",
            source_line = 587,
            slots = {
                {
                    spell_id = "SPELL_HEAL_OTHER",
                    source_line = 589,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_ALLIGATOR",
            source_line = 594,
            slots = {
                {
                    spell_id = "SPELL_SPRINT",
                    source_line = 596,
                    frequency = 31,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_FIRE_CRAB",
            source_line = 600,
            slots = {
                {
                    spell_id = "SPELL_FLAMING_CLOUD",
                    source_line = 602,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_GHOST_CRAB",
            source_line = 606,
            slots = {
                {
                    spell_id = "SPELL_SPECTRAL_CLOUD",
                    source_line = 608,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_APOCALYPSE_CRAB",
            source_line = 612,
            slots = {
                {
                    spell_id = "SPELL_CHAOS_BREATH",
                    source_line = 614,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_WILL_O_THE_WISP",
            source_line = 619,
            slots = {
                {
                    spell_id = "SPELL_MARSHLIGHT",
                    source_line = 621,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 622,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_DART_SLUG",
            source_line = 627,
            slots = {
                {
                    spell_id = "SPELL_SLUG_DART",
                    source_line = 629,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_SWAMP_WORM",
            source_line = 633,
            slots = {
                {
                    spell_id = "SPELL_HARPOON_SHOT",
                    source_line = 635,
                    frequency = 80,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_WORLDBINDER",
            source_line = 640,
            slots = {
                {
                    spell_id = "SPELL_FORCEFUL_INVITATION",
                    source_line = 642,
                    frequency = 58,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_BUNYIP",
            source_line = 646,
            slots = {
                {
                    spell_id = "SPELL_WARNING_CRY",
                    source_line = 648,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_VOCAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_MELIAI",
            source_line = 653,
            slots = {
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 655,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_HEAL_OTHER",
                    source_line = 656,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_QUEEN_BEE",
            source_line = 660,
            slots = {
                {
                    spell_id = "SPELL_BERSERK_OTHER",
                    source_line = 662,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_BERSERK_OTHER",
                    source_line = 663,
                    frequency = 75,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_SPARK_WASP",
            source_line = 667,
            slots = {
                {
                    spell_id = "SPELL_BLINKBOLT",
                    source_line = 669,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_LONG_RANGE",
                    },
                },
            },
        },
        {
            id = "MST_MOTH_OF_WRATH",
            source_line = 673,
            slots = {
                {
                    spell_id = "SPELL_BERSERK_OTHER",
                    source_line = 675,
                    frequency = 66,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_SUN_MOTH",
            source_line = 679,
            slots = {
                {
                    spell_id = "SPELL_STICKY_FLAME_RANGE",
                    source_line = 681,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_ENERGY_BOLT",
                    source_line = 682,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_ANCIENT_CHAMPION",
            source_line = 687,
            slots = {
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 689,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 690,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_CURSE_SKULL",
            source_line = 694,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_UNDEAD",
                    source_line = 696,
                    frequency = 48,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 697,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_CURSE_TOE",
            source_line = 701,
            slots = {
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 703,
                    frequency = 26,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_MUSHROOMS",
                    source_line = 704,
                    frequency = 39,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_OPHAN",
            source_line = 709,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 711,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_HOLY_FLAMES",
                    source_line = 712,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ANGEL",
            source_line = 716,
            slots = {
                {
                    spell_id = "SPELL_MINOR_HEALING",
                    source_line = 718,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_DAEVA",
            source_line = 722,
            slots = {
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 724,
                    frequency = 64,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SERAPH",
            source_line = 728,
            slots = {
                {
                    spell_id = "SPELL_WARNING_CRY",
                    source_line = 730,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_VOCAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_HOLIES",
                    source_line = 731,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_INJURY_BOND",
                    source_line = 732,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CLEANSING_FLAME",
                    source_line = 733,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_BOULDER_BEETLE",
            source_line = 738,
            slots = {
                {
                    spell_id = "SPELL_ROLL",
                    source_line = 740,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_AWAY",
                    source_line = 741,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_RADROACH",
            source_line = 745,
            slots = {
                {
                    spell_id = "SPELL_IRRADIATE",
                    source_line = 747,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_FIRE_GIANT",
            source_line = 752,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 754,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 755,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_FROST_GIANT",
            source_line = 759,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 761,
                    frequency = 66,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_TITAN",
            source_line = 765,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 767,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MINOR_HEALING",
                    source_line = 768,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AIRSTRIKE",
                    source_line = 769,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_IRON_GIANT",
            source_line = 773,
            slots = {
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 775,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HARPOON_SHOT",
                    source_line = 776,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_THROW_ALLY",
                    source_line = 777,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_TAINTED_LEVIATHAN",
            source_line = 781,
            slots = {
                {
                    spell_id = "SPELL_MESMERISE",
                    source_line = 783,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_STEAM_DRAGON",
            source_line = 788,
            slots = {
                {
                    spell_id = "SPELL_STEAM_BALL",
                    source_line = 790,
                    frequency = 54,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_ACID_DRAGON",
            source_line = 795,
            slots = {
                {
                    spell_id = "SPELL_SPIT_ACID",
                    source_line = 797,
                    frequency = 55,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_SWAMP_DRAGON",
            source_line = 802,
            slots = {
                {
                    spell_id = "SPELL_POISONOUS_CLOUD",
                    source_line = 804,
                    frequency = 59,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_FIRE_DRAGON_BREATH",
            source_line = 809,
            slots = {
                {
                    spell_id = "SPELL_FIRE_BREATH",
                    source_line = 811,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_ICE_DRAGON_BREATH",
            source_line = 816,
            slots = {
                {
                    spell_id = "SPELL_COLD_BREATH",
                    source_line = 818,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_STORM_DRAGON",
            source_line = 823,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 825,
                    frequency = 64,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_SHADOW_DRAGON",
            source_line = 830,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 832,
                    frequency = 67,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_QUICKSILVER_DRAGON",
            source_line = 836,
            slots = {
                {
                    spell_id = "SPELL_QUICKSILVER_BOLT",
                    source_line = 838,
                    frequency = 66,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_GOLDEN_DRAGON",
            source_line = 843,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 845,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 847,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_POISONOUS_CLOUD",
                    source_line = 849,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_PEARL_DRAGON",
            source_line = 854,
            slots = {
                {
                    spell_id = "SPELL_HOLY_BREATH",
                    source_line = 856,
                    frequency = 68,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_AIR_ELEMENTAL",
            source_line = 862,
            slots = {
                {
                    spell_id = "SPELL_STUNNING_BURST",
                    source_line = 864,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_ELEMENTAL_WELLSPRING",
            source_line = 868,
            slots = {
                {
                    spell_id = "SPELL_PRIMAL_WAVE",
                    source_line = 870,
                    frequency = 65,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_WATER_ELEMENTALS",
                    source_line = 871,
                    frequency = 65,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_IRON_ELEMENTAL",
            source_line = 875,
            slots = {
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 877,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_METAL_SPLINTERS",
                    source_line = 878,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 879,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_FLOATING_EYE",
            source_line = 884,
            slots = {
                {
                    spell_id = "SPELL_PARALYSIS_GAZE",
                    source_line = 886,
                    frequency = 80,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_INSTANT",
                    },
                },
            },
        },
        {
            id = "MST_GOLDEN_EYE",
            source_line = 890,
            slots = {
                {
                    spell_id = "SPELL_CONFUSION_GAZE",
                    source_line = 892,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_INSTANT",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 893,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_EYE_OF_DEVASTATION",
            source_line = 897,
            slots = {
                {
                    spell_id = "SPELL_ENERGY_BOLT",
                    source_line = 899,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SHINING_EYE",
            source_line = 903,
            slots = {
                {
                    spell_id = "SPELL_MALMUTATE",
                    source_line = 905,
                    frequency = 57,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_GREAT_ORB_OF_EYES",
            source_line = 909,
            slots = {
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 911,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MINDBURST",
                    source_line = 912,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_DRAIN_MAGIC",
                    source_line = 913,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 914,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_GLOWING_ORANGE_BRAIN",
            source_line = 918,
            slots = {
                {
                    spell_id = "SPELL_BRAIN_FEED",
                    source_line = 920,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CAUSE_FEAR",
                    source_line = 921,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SHADOW_CREATURES",
                    source_line = 922,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MASS_CONFUSION",
                    source_line = 923,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 924,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_MANTICORE",
            source_line = 929,
            slots = {
                {
                    spell_id = "SPELL_THROW_BARBS",
                    source_line = 931,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_FENSTRIDER_WITCH",
            source_line = 935,
            slots = {
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 937,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AGONY",
                    source_line = 938,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HURL_SLUDGE",
                    source_line = 939,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SPHINX",
            source_line = 943,
            slots = {
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 945,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 946,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 947,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 948,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_JOROGUMO",
            source_line = 953,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 955,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_ENSNARE",
                    source_line = 956,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_KOBOLD_DEMONOLOGIST",
            source_line = 961,
            slots = {
                {
                    spell_id = "SPELL_CANTRIP",
                    source_line = 963,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_MINOR_DEMON",
                    source_line = 964,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DEMON",
                    source_line = 965,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_REVENANT",
            source_line = 970,
            slots = {
                {
                    spell_id = "SPELL_SPECTRAL_CLOUD",
                    source_line = 972,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_GHOSTLY_FIREBALL",
                    source_line = 973,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
                    source_line = 974,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_AWAY",
                    source_line = 975,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_LICH",
            source_line = 979,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 981,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_IOOD",
                    source_line = 982,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 983,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 984,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 985,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_ANCIENT_LICH",
            source_line = 989,
            slots = {
                {
                    spell_id = "SPELL_CORROSIVE_BOLT",
                    source_line = 991,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
                    source_line = 992,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 993,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_PETRIFY",
                    source_line = 994,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 995,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DREAD_LICH",
            source_line = 999,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_GREATER_DEMON",
                    source_line = 1001,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 1002,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1003,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 1004,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_STOKER",
            source_line = 1008,
            slots = {
                {
                    spell_id = "SPELL_WIND_BLAST",
                    source_line = 1011,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_STOKE_FLAMES",
                    source_line = 1012,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_MUMMY_PRIEST",
            source_line = 1018,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_DEMON",
                    source_line = 1020,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_UNDEAD",
                    source_line = 1021,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 1022,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1023,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_ROYAL_MUMMY",
            source_line = 1027,
            slots = {
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 1029,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1030,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_EMPEROR_SCORPIONS",
                    source_line = 1031,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_SCARABS",
                    source_line = 1032,
                    frequency = 26,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NAGA",
            source_line = 1037,
            slots = {
                {
                    spell_id = "SPELL_SPIT_POISON",
                    source_line = 1039,
                    frequency = 55,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_NAGA_WARRIOR",
            source_line = 1043,
            slots = {
                {
                    spell_id = "SPELL_SPIT_POISON",
                    source_line = 1045,
                    frequency = 55,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_BATTLECRY",
                    source_line = 1046,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
            },
        },
        {
            id = "MST_NAGA_MAGE",
            source_line = 1050,
            slots = {
                {
                    spell_id = "SPELL_SPIT_POISON",
                    source_line = 1052,
                    frequency = 55,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_VENOM_BOLT",
                    source_line = 1053,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CONCENTRATE_VENOM",
                    source_line = 1054,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1055,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NAGARAJA",
            source_line = 1059,
            slots = {
                {
                    spell_id = "SPELL_SPIT_POISON",
                    source_line = 1061,
                    frequency = 55,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_VENOM_BOLT",
                    source_line = 1062,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_POISON_ARROW",
                    source_line = 1063,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_DIMENSION_ANCHOR",
                    source_line = 1064,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1065,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NAGA_SHARPSHOOTER",
            source_line = 1069,
            slots = {
                {
                    spell_id = "SPELL_SPIT_POISON",
                    source_line = 1071,
                    frequency = 55,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_PORTAL_PROJECTILE",
                    source_line = 1072,
                    frequency = 59,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NAGA_RITUALIST",
            source_line = 1076,
            slots = {
                {
                    spell_id = "SPELL_SPIT_POISON",
                    source_line = 1078,
                    frequency = 55,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_OLGREBS_TOXIC_RADIANCE",
                    source_line = 1079,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_VIRULENCE",
                    source_line = 1080,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_SALAMANDER_MYSTIC",
            source_line = 1084,
            slots = {
                {
                    spell_id = "SPELL_FORCE_LANCE",
                    source_line = 1086,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_MAGMA",
                    source_line = 1087,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE_OTHER",
                    source_line = 1088,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SALAMANDER_TYRANT",
            source_line = 1092,
            slots = {
                {
                    spell_id = "SPELL_ERUPTION",
                    source_line = 1094,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_PYROCLASTIC_SURGE",
                    source_line = 1095,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_WEAKENING_GAZE",
                    source_line = 1096,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_INSTANT",
                    },
                },
            },
        },
        {
            id = "MST_OGRE_MAGE",
            source_line = 1101,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_MAGMA",
                    source_line = 1103,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE_OTHER",
                    source_line = 1104,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 1105,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 1106,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_IRONBOUND_THUNDERHULK",
            source_line = 1110,
            slots = {
                {
                    spell_id = "SPELL_CALL_DOWN_LIGHTNING",
                    source_line = 1112,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_RANGE",
                    source_line = 1113,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_BURNING_BUSH",
            source_line = 1118,
            slots = {
                {
                    spell_id = "SPELL_THROW_FLAME",
                    source_line = 1120,
                    frequency = 67,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_OKLOB_SAPLING",
            source_line = 1124,
            slots = {
                {
                    spell_id = "SPELL_SPIT_ACID",
                    source_line = 1126,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_BALLISTOMYCETE",
            source_line = 1130,
            slots = {
                {
                    spell_id = "SPELL_SPORULATE",
                    source_line = 1132,
                    frequency = 67,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_STARFLOWER",
            source_line = 1136,
            slots = {
                {
                    spell_id = "SPELL_HARPOON_SHOT",
                    source_line = 1138,
                    frequency = 80,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_TENGU_CONJURER",
            source_line = 1143,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 1145,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BATTLESPHERE",
                    source_line = 1146,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1147,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_TENGU_REAVER",
            source_line = 1151,
            slots = {
                {
                    spell_id = "SPELL_VENOM_BOLT",
                    source_line = 1153,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 1154,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 1155,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CORROSIVE_BOLT",
                    source_line = 1156,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 1157,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 1158,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_RAKSHASA",
            source_line = 1163,
            slots = {
                {
                    spell_id = "SPELL_FORCE_LANCE",
                    source_line = 1165,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_PHANTOM_MIRROR",
                    source_line = 1166,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1167,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_EFREET",
            source_line = 1171,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 1173,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 1174,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_DRYAD",
            source_line = 1178,
            slots = {
                {
                    spell_id = "SPELL_AWAKEN_VINES",
                    source_line = 1180,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AWAKEN_FOREST",
                    source_line = 1181,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MINOR_HEALING",
                    source_line = 1182,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_ELEIONOMA",
            source_line = 1186,
            slots = {
                {
                    spell_id = "SPELL_SPLINTERSPRAY",
                    source_line = 1188,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_WOODWEAL",
                    source_line = 1189,
                    frequency = 150,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_WENDIGO",
            source_line = 1193,
            slots = {
                {
                    spell_id = "SPELL_SERACFALL",
                    source_line = 1195,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_STUNNING_BURST",
                    source_line = 1196,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_LAVA_SNAKE",
            source_line = 1201,
            slots = {
                {
                    spell_id = "SPELL_SPIT_LAVA",
                    source_line = 1203,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_GUARDIAN_SERPENT",
            source_line = 1207,
            slots = {
                {
                    spell_id = "SPELL_VENOM_BOLT",
                    source_line = 1209,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 1210,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_ALLIES_ENCIRCLE",
                    source_line = 1211,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SHOCK_SERPENT",
            source_line = 1215,
            slots = {
                {
                    spell_id = "SPELL_ELECTRICAL_BOLT",
                    source_line = 1217,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_TROLL_EARTH_MAGE",
            source_line = 1222,
            slots = {
                {
                    spell_id = "SPELL_LRD",
                    source_line = 1224,
                    frequency = 31,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_DIG",
                    source_line = 1225,
                    frequency = 31,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DEEP_TROLL_SHAMAN",
            source_line = 1229,
            slots = {
                {
                    spell_id = "SPELL_HASTE_OTHER",
                    source_line = 1231,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_MIGHT_OTHER",
                    source_line = 1232,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_VAMPIRE",
            source_line = 1237,
            slots = {
                {
                    spell_id = "SPELL_VAMPIRIC_DRAINING",
                    source_line = 1239,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 1240,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 1241,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_VAMPIRE_MAGE",
            source_line = 1245,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 1247,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_UNDEAD",
                    source_line = 1248,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 1249,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_VAMPIRIC_DRAINING",
                    source_line = 1250,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_VAMPIRE_KNIGHT",
            source_line = 1254,
            slots = {
                {
                    spell_id = "SPELL_BLINK_CLOSE",
                    source_line = 1256,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 1257,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1258,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 1259,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_VAMPIRIC_DRAINING",
                    source_line = 1260,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SHADOW",
            source_line = 1265,
            slots = {
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 1267,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_PHANTASMAL_WARRIOR",
            source_line = 1271,
            slots = {
                {
                    spell_id = "SPELL_BLINK_CLOSE",
                    source_line = 1273,
                    frequency = 67,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_EIDOLON",
            source_line = 1277,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 1279,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CAUSE_FEAR",
                    source_line = 1280,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_FLAYED_GHOST",
            source_line = 1284,
            slots = {
                {
                    spell_id = "SPELL_FLAY",
                    source_line = 1286,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_PUTRID_MOUTH",
            source_line = 1290,
            slots = {
                {
                    spell_id = "SPELL_MIASMA_BREATH",
                    source_line = 1292,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_WARNING_CRY",
                    source_line = 1293,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_VOCAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_KRAKEN",
            source_line = 1298,
            slots = {
                {
                    spell_id = "SPELL_CREATE_TENTACLES",
                    source_line = 1300,
                    frequency = 44,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_INK_CLOUD",
                    source_line = 1301,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_THRASHING_HORROR",
            source_line = 1305,
            slots = {
                {
                    spell_id = "SPELL_MIGHT",
                    source_line = 1307,
                    frequency = 59,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_TENTACLED_STARSPAWN",
            source_line = 1311,
            slots = {
                {
                    spell_id = "SPELL_CREATE_TENTACLES",
                    source_line = 1313,
                    frequency = 66,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_NAMELESS",
            source_line = 1317,
            slots = {
                {
                    spell_id = "SPELL_ABJURATION",
                    source_line = 1319,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_MLIOGLOTL",
            source_line = 1323,
            slots = {
                {
                    spell_id = "SPELL_MIGHT",
                    source_line = 1325,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_CAUSE_FEAR",
                    source_line = 1326,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_CORRUPT_LOCALE",
                    source_line = 1327,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_CATOBLEPAS",
            source_line = 1332,
            slots = {
                {
                    spell_id = "SPELL_PETRIFYING_CLOUD",
                    source_line = 1334,
                    frequency = 41,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_DREAM_SHEEP",
            source_line = 1338,
            slots = {
                {
                    spell_id = "SPELL_DREAM_DUST",
                    source_line = 1340,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_HELLEPHANT",
            source_line = 1344,
            slots = {
                {
                    spell_id = "SPELL_FIRE_BREATH",
                    source_line = 1346,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1347,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_WHITE_IMP",
            source_line = 1352,
            slots = {
                {
                    spell_id = "SPELL_THROW_FROST",
                    source_line = 1354,
                    frequency = 52,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SHADOW_IMP",
            source_line = 1358,
            slots = {
                {
                    spell_id = "SPELL_PAIN",
                    source_line = 1360,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_YNOXINUL",
            source_line = 1365,
            slots = {
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 1367,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_UFETUBUS",
                    source_line = 1368,
                    frequency = 38,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SMOKE_DEMON",
            source_line = 1372,
            slots = {
                {
                    spell_id = "SPELL_STICKY_FLAME_RANGE",
                    source_line = 1374,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_STEAM_BALL",
                    source_line = 1375,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 1376,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SOUL_EATER",
            source_line = 1380,
            slots = {
                {
                    spell_id = "SPELL_DRAIN_LIFE",
                    source_line = 1382,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_NEQOXEC",
            source_line = 1386,
            slots = {
                {
                    spell_id = "SPELL_MALMUTATE",
                    source_line = 1388,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BRAIN_FEED",
                    source_line = 1389,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SHADOW_DEMON",
            source_line = 1394,
            slots = {
                {
                    spell_id = "SPELL_SHADOW_CREATURES",
                    source_line = 1396,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_GREEN_DEATH",
            source_line = 1400,
            slots = {
                {
                    spell_id = "SPELL_POISON_ARROW",
                    source_line = 1402,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_POISONOUS_CLOUD",
                    source_line = 1403,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_VENOM_BOLT",
                    source_line = 1404,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_BALRUG",
            source_line = 1408,
            slots = {
                {
                    spell_id = "SPELL_STICKY_FLAME_RANGE",
                    source_line = 1410,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 1411,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 1412,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 1413,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_BLIZZARD_DEMON",
            source_line = 1417,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 1419,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 1420,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FREEZING_CLOUD",
                    source_line = 1421,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_AIRSTRIKE",
                    source_line = 1422,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_CACODEMON",
            source_line = 1426,
            slots = {
                {
                    spell_id = "SPELL_ENERGY_BOLT",
                    source_line = 1428,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 1429,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 1430,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MALMUTATE",
                    source_line = 1431,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_DIG",
                    source_line = 1432,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_HELLION",
            source_line = 1436,
            slots = {
                {
                    spell_id = "SPELL_CALL_DOWN_DAMNATION",
                    source_line = 1438,
                    frequency = 57,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_TORMENTOR",
            source_line = 1442,
            slots = {
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1444,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_EXECUTIONER",
            source_line = 1449,
            slots = {
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1451,
                    frequency = 41,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_BRIMSTONE_FIEND",
            source_line = 1455,
            slots = {
                {
                    spell_id = "SPELL_HURL_DAMNATION",
                    source_line = 1457,
                    frequency = 34,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1458,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ICE_FIEND",
            source_line = 1462,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 1464,
                    frequency = 46,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1465,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_TZITZIMITL",
            source_line = 1469,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 1471,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1472,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
                    source_line = 1473,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_HELL_SENTINEL",
            source_line = 1477,
            slots = {
                {
                    spell_id = "SPELL_HURL_DAMNATION",
                    source_line = 1479,
                    frequency = 28,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 1480,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_DEMONSPAWN_WARMONGER",
            source_line = 1485,
            slots = {
                {
                    spell_id = "SPELL_SAP_MAGIC",
                    source_line = 1487,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_HASTE_OTHER",
                    source_line = 1488,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_DEMONSPAWN_BLOOD_SAINT",
            source_line = 1492,
            slots = {
                {
                    spell_id = "SPELL_LEGENDARY_DESTRUCTION",
                    source_line = 1494,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_CALL_OF_CHAOS",
                    source_line = 1495,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_DEMONSPAWN_CORRUPTER",
            source_line = 1499,
            slots = {
                {
                    spell_id = "SPELL_PLANEREND",
                    source_line = 1501,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_ENTROPIC_WEAVE",
                    source_line = 1502,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_DEMONSPAWN_BLACK_SUN",
            source_line = 1506,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 1508,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
                    source_line = 1509,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_BLACK_MARK",
                    source_line = 1510,
                    frequency = 28,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_USHABTI",
            source_line = 1515,
            slots = {
                {
                    spell_id = "SPELL_DEATH_RATTLE",
                    source_line = 1517,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_WARNING_CRY",
                    source_line = 1518,
                    frequency = 56,
                    flags = {
                        "MON_SPELL_VOCAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
                    source_line = 1519,
                    frequency = 44,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_PEACEKEEPER",
            source_line = 1523,
            slots = {
                {
                    spell_id = "SPELL_THROW_BARBS",
                    source_line = 1525,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
                {
                    spell_id = "SPELL_BATTLECRY",
                    source_line = 1526,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
            },
        },
        {
            id = "MST_CRYSTAL_GUARDIAN",
            source_line = 1530,
            slots = {
                {
                    spell_id = "SPELL_CRYSTAL_BOLT",
                    source_line = 1532,
                    frequency = 66,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ELECTRIC_GOLEM",
            source_line = 1536,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 1538,
                    frequency = 44,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1539,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ICE_STATUE",
            source_line = 1543,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 1545,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_THROW_ICICLE",
                    source_line = 1546,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FREEZING_CLOUD",
                    source_line = 1547,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_ICE_BEAST",
                    source_line = 1548,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_OBSIDIAN_STATUE",
            source_line = 1552,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_MINOR_DEMON",
                    source_line = 1554,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DEMON",
                    source_line = 1555,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MESMERISE",
                    source_line = 1556,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ORANGE_CRYSTAL_STATUE",
            source_line = 1560,
            slots = {
                {
                    spell_id = "SPELL_SHADOW_CREATURES",
                    source_line = 1562,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BRAIN_FEED",
                    source_line = 1563,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_DRAINING_GAZE",
                    source_line = 1564,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MASS_CONFUSION",
                    source_line = 1565,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_STRANGE_MACHINE",
            source_line = 1569,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_ILLUSION",
                    source_line = 1571,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SHADOW_CREATURES",
                    source_line = 1572,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_GARGOYLE",
            source_line = 1577,
            slots = {
                {
                    spell_id = "SPELL_STONE_ARROW",
                    source_line = 1579,
                    frequency = 56,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_MOLTEN_GARGOYLE",
            source_line = 1583,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_MAGMA",
                    source_line = 1585,
                    frequency = 57,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_NARGUN",
            source_line = 1589,
            slots = {
                {
                    spell_id = "SPELL_PETRIFY",
                    source_line = 1591,
                    frequency = 66,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_WRETCHED_STAR",
            source_line = 1596,
            slots = {
                {
                    spell_id = "SPELL_FORCE_LANCE",
                    source_line = 1598,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CORRUPTING_PULSE",
                    source_line = 1599,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ORB_OF_FIRE",
            source_line = 1603,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 1605,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 1606,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MALMUTATE",
                    source_line = 1607,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_WALKING_TOME",
            source_line = 1612,
            slots = {
                {
                    spell_id = "SPELL_CONJURE_LIVING_SPELLS",
                    source_line = 1614,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ZENATA",
            source_line = 1623,
            slots = {
                {
                    spell_id = "SPELL_RESONANCE_STRIKE",
                    source_line = 1625,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SHEZAS_DANCE",
                    source_line = 1626,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NESSOS",
            source_line = 1631,
            slots = {
                {
                    spell_id = "SPELL_BLINK_RANGE",
                    source_line = 1633,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1634,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_BAI_SUZHEN",
            source_line = 1639,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_HYDRA",
                    source_line = 1641,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_DOWAN",
            source_line = 1646,
            slots = {
                {
                    spell_id = "SPELL_THROW_FLAME",
                    source_line = 1648,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_THROW_FROST",
                    source_line = 1649,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1650,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CORONA",
                    source_line = 1651,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE_OTHER",
                    source_line = 1652,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_FANNAR",
            source_line = 1656,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 1658,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_OZOCUBUS_REFRIGERATION",
                    source_line = 1659,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_ICE_BEAST",
                    source_line = 1660,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1661,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_ROBIN",
            source_line = 1666,
            slots = {
                {
                    spell_id = "SPELL_BATTLECRY",
                    source_line = 1668,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
                {
                    spell_id = "SPELL_THROW_ALLY",
                    source_line = 1669,
                    frequency = 80,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_JORGRUN",
            source_line = 1673,
            slots = {
                {
                    spell_id = "SPELL_LRD",
                    source_line = 1675,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_GRASPING_ROOTS",
                    source_line = 1676,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 1677,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_PETRIFY",
                    source_line = 1678,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_DIG",
                    source_line = 1679,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NATASHA",
            source_line = 1684,
            slots = {
                {
                    spell_id = "SPELL_MAGIC_DART",
                    source_line = 1686,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CALL_IMP",
                    source_line = 1687,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 1688,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_THE_ENCHANTRESS",
            source_line = 1693,
            slots = {
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 1695,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_DIMENSION_ANCHOR",
                    source_line = 1696,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MASS_CONFUSION",
                    source_line = 1697,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_STRIP_WILLPOWER",
                    source_line = 1698,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1699,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_REPEL_MISSILES",
                    source_line = 1700,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_ILSUIW",
            source_line = 1705,
            slots = {
                {
                    spell_id = "SPELL_THROW_ICICLE",
                    source_line = 1707,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_WATER_ELEMENTALS",
                    source_line = 1708,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CALL_TIDE",
                    source_line = 1709,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 1710,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1711,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_BLORK",
            source_line = 1716,
            slots = {
                {
                    spell_id = "SPELL_CANTRIP",
                    source_line = 1718,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MAGIC_DART",
                    source_line = 1719,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_THROW_FROST",
                    source_line = 1720,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_THROW_FLAME",
                    source_line = 1721,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1722,
                    frequency = 9,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NERGALLE",
            source_line = 1726,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_DRAINING",
                    source_line = 1728,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_SPECTRAL_ORCS",
                    source_line = 1729,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE_OTHER",
                    source_line = 1730,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SAINT_ROKA",
            source_line = 1734,
            slots = {
                {
                    spell_id = "SPELL_BATTLECRY",
                    source_line = 1736,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 1737,
                    frequency = 64,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_GASTRONOK",
            source_line = 1742,
            slots = {
                {
                    spell_id = "SPELL_CANTRIP",
                    source_line = 1744,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AIRSTRIKE",
                    source_line = 1745,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_SMALL_MAMMAL",
                    source_line = 1746,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 1747,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SPRINT",
                    source_line = 1748,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_MURRAY",
            source_line = 1753,
            slots = {
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1755,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_UNDEAD",
                    source_line = 1756,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_BLACK_MARK",
                    source_line = 1757,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_NOISY",
                    },
                },
            },
        },
        {
            id = "MST_MENNAS",
            source_line = 1762,
            slots = {
                {
                    spell_id = "SPELL_MASS_CONFUSION",
                    source_line = 1764,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SILENCE",
                    source_line = 1765,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MINOR_HEALING",
                    source_line = 1766,
                    frequency = 34,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_POLYPHEMUS",
            source_line = 1771,
            slots = {
                {
                    spell_id = "SPELL_THROW_ALLY",
                    source_line = 1773,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_XTAHUA",
            source_line = 1778,
            slots = {
                {
                    spell_id = "SPELL_SEARING_BREATH",
                    source_line = 1780,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 1782,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
            },
        },
        {
            id = "MST_BAI_SUZHEN_DRAGON",
            source_line = 1786,
            slots = {
                {
                    spell_id = "SPELL_PRIMAL_WAVE",
                    source_line = 1788,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
            },
        },
        {
            id = "MST_SERPENT_OF_HELL_GEH",
            source_line = 1792,
            slots = {
                {
                    spell_id = "SPELL_SERPENT_OF_HELL_GEH_BREATH",
                    source_line = 1794,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DRAGON",
                    source_line = 1796,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SERPENT_OF_HELL_COC",
            source_line = 1800,
            slots = {
                {
                    spell_id = "SPELL_SERPENT_OF_HELL_COC_BREATH",
                    source_line = 1802,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DRAGON",
                    source_line = 1804,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SERPENT_OF_HELL_DIS",
            source_line = 1808,
            slots = {
                {
                    spell_id = "SPELL_SERPENT_OF_HELL_DIS_BREATH",
                    source_line = 1810,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DRAGON",
                    source_line = 1812,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SERPENT_OF_HELL_TAR",
            source_line = 1816,
            slots = {
                {
                    spell_id = "SPELL_SERPENT_OF_HELL_TAR_BREATH",
                    source_line = 1818,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                        "MON_SPELL_NOISY",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DRAGON",
                    source_line = 1820,
                    frequency = 35,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ARACHNE",
            source_line = 1825,
            slots = {
                {
                    spell_id = "SPELL_VENOM_BOLT",
                    source_line = 1827,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_POISON_ARROW",
                    source_line = 1828,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_ENSNARE",
                    source_line = 1829,
                    frequency = 34,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1830,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_ASTERION",
            source_line = 1834,
            slots = {
                {
                    spell_id = "SPELL_MAJOR_DESTRUCTION",
                    source_line = 1836,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_GREATER_SERVANT_MAKHLEB",
                    source_line = 1837,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1838,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_ENDOPLASM",
            source_line = 1843,
            slots = {
                {
                    spell_id = "SPELL_FREEZE",
                    source_line = 1845,
                    frequency = 70,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_DISSOLUTION",
            source_line = 1849,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_EYEBALLS",
                    source_line = 1851,
                    frequency = 62,
                    flags = {
                        "MON_SPELL_PRIEST",
                    },
                },
            },
        },
        {
            id = "MST_SONJA",
            source_line = 1856,
            slots = {
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1858,
                    frequency = 28,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_BORIS",
            source_line = 1863,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 1865,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 1866,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_IOOD",
                    source_line = 1867,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 1868,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_MENKAURE",
            source_line = 1873,
            slots = {
                {
                    spell_id = "SPELL_PAIN",
                    source_line = 1875,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1876,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1877,
                    frequency = 18,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_KHUFU",
            source_line = 1881,
            slots = {
                {
                    spell_id = "SPELL_SMITING",
                    source_line = 1883,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 1884,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_EMPEROR_SCORPIONS",
                    source_line = 1885,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_SCARABS",
                    source_line = 1886,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1887,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_VASHNIA",
            source_line = 1892,
            slots = {
                {
                    spell_id = "SPELL_SPIT_POISON",
                    source_line = 1894,
                    frequency = 55,
                    flags = {
                        "MON_SPELL_NATURAL",
                        "MON_SPELL_BREATH",
                    },
                },
                {
                    spell_id = "SPELL_PORTAL_PROJECTILE",
                    source_line = 1895,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_OTHER",
                    source_line = 1896,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_ALLIES_AWAY",
                    source_line = 1897,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_AWAY",
                    source_line = 1898,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_LODUL",
            source_line = 1903,
            slots = {
                {
                    spell_id = "SPELL_CALL_DOWN_LIGHTNING",
                    source_line = 1905,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_SOJOBO",
            source_line = 1910,
            slots = {
                {
                    spell_id = "SPELL_WIND_BLAST",
                    source_line = 1912,
                    frequency = 28,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 1913,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AIRSTRIKE",
                    source_line = 1914,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_AIR_ELEMENTALS",
                    source_line = 1915,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_REPEL_MISSILES",
                    source_line = 1916,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_AZRAEL",
            source_line = 1921,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 1923,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_STICKY_FLAME_RANGE",
                    source_line = 1924,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 1925,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_HURL_DAMNATION",
                    source_line = 1926,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CALL_DOWN_DAMNATION",
                    source_line = 1927,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_MARA",
            source_line = 1931,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 1933,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FAKE_MARA_SUMMON",
                    source_line = 1934,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_ILLUSION",
                    source_line = 1935,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1936,
                    frequency = 29,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_AIZUL",
            source_line = 1941,
            slots = {
                {
                    spell_id = "SPELL_VENOM_BOLT",
                    source_line = 1943,
                    frequency = 32,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_POISON_ARROW",
                    source_line = 1944,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLEEP",
                    source_line = 1945,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_SNORG",
            source_line = 1950,
            slots = {
                {
                    spell_id = "SPELL_BERSERKER_RAGE",
                    source_line = 1952,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_MOON_TROLL",
            source_line = 1956,
            slots = {
                {
                    spell_id = "SPELL_CORROSIVE_BOLT",
                    source_line = 1958,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_JORY",
            source_line = 1963,
            slots = {
                {
                    spell_id = "SPELL_VAMPIRIC_DRAINING",
                    source_line = 1965,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
                    source_line = 1966,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MESMERISE",
                    source_line = 1967,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_CLOSE",
                    source_line = 1968,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_GRINDER",
            source_line = 1973,
            slots = {
                {
                    spell_id = "SPELL_PAIN",
                    source_line = 1975,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 1976,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 1977,
                    frequency = 19,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_IGNACIO",
            source_line = 1982,
            slots = {
                {
                    spell_id = "SPELL_AGONY_RANGE",
                    source_line = 1984,
                    frequency = 21,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 1985,
                    frequency = 41,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_AMAEMON",
            source_line = 1990,
            slots = {
                {
                    spell_id = "SPELL_CONCENTRATE_VENOM",
                    source_line = 1992,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_SCORPIONS",
                    source_line = 1993,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_ROXANNE",
            source_line = 1998,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_MAGMA",
                    source_line = 2000,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 2001,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
                    source_line = 2002,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_OTHER_CLOSE",
                    source_line = 2003,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_VV",
            source_line = 2008,
            slots = {
                {
                    spell_id = "SPELL_ERUPTION",
                    source_line = 2010,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_PYROCLASTIC_SURGE",
                    source_line = 2011,
                    frequency = 50,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CREEPING_FROST",
                    source_line = 2012,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_JESSICA",
            source_line = 2017,
            slots = {
                {
                    spell_id = "SPELL_PAIN",
                    source_line = 2019,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 2020,
                    frequency = 8,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 2021,
                    frequency = 8,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 2022,
                    frequency = 17,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_EUSTACHIO",
            source_line = 2026,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_SMALL_MAMMAL",
                    source_line = 2028,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_MINOR_DEMON",
                    source_line = 2029,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 2030,
                    frequency = 27,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_ERICA",
            source_line = 2034,
            slots = {
                {
                    spell_id = "SPELL_VENOM_BOLT",
                    source_line = 2036,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_FORCE_LANCE",
                    source_line = 2037,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 2038,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 2039,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 2040,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_MAURICE",
            source_line = 2044,
            slots = {
                {
                    spell_id = "SPELL_SPRINT",
                    source_line = 2046,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 2047,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 2048,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_HAROLD",
            source_line = 2052,
            slots = {
                {
                    spell_id = "SPELL_HARPOON_SHOT",
                    source_line = 2054,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SENTINEL_MARK",
                    source_line = 2055,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_JOSEPHINE",
            source_line = 2059,
            slots = {
                {
                    spell_id = "SPELL_VAMPIRIC_DRAINING",
                    source_line = 2061,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_GHOSTLY_FIREBALL",
                    source_line = 2062,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
                    source_line = 2063,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_JOSEPHINA",
            source_line = 2067,
            slots = {
                {
                    spell_id = "SPELL_SERACFALL",
                    source_line = 2069,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_GHOSTLY_FIREBALL",
                    source_line = 2070,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BIND_SOULS",
                    source_line = 2071,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_FLASH_FREEZE",
                    source_line = 2072,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_RUPERT",
            source_line = 2076,
            slots = {
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 2078,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
                {
                    spell_id = "SPELL_CONFUSE",
                    source_line = 2079,
                    frequency = 16,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
                {
                    spell_id = "SPELL_BERSERKER_RAGE",
                    source_line = 2080,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_NATURAL",
                    },
                },
            },
        },
        {
            id = "MST_LOUISE",
            source_line = 2084,
            slots = {
                {
                    spell_id = "SPELL_STONE_ARROW",
                    source_line = 2086,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 2087,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BANISHMENT",
                    source_line = 2088,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 2089,
                    frequency = 10,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_FRANCES",
            source_line = 2093,
            slots = {
                {
                    spell_id = "SPELL_THROW_ICICLE",
                    source_line = 2095,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 2096,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DEMON",
                    source_line = 2097,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 2098,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_KIRKE",
            source_line = 2102,
            slots = {
                {
                    spell_id = "SPELL_PORKALATOR",
                    source_line = 2104,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SLOW",
                    source_line = 2105,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MONSTROUS_MENAGERIE",
                    source_line = 2106,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 2107,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_DONALD",
            source_line = 2111,
            slots = {
                {
                    spell_id = "SPELL_MIGHT",
                    source_line = 2113,
                    frequency = 34,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 2114,
                    frequency = 34,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_HELLBINDER",
            source_line = 2118,
            slots = {
                {
                    spell_id = "SPELL_HURL_DAMNATION",
                    source_line = 2120,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_GREATER_DEMON",
                    source_line = 2121,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_DEMON",
                    source_line = 2122,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 2123,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_AWAY",
                    source_line = 2124,
                    frequency = 14,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_CLOUD_MAGE",
            source_line = 2128,
            slots = {
                {
                    spell_id = "SPELL_AIRSTRIKE",
                    source_line = 2130,
                    frequency = 25,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_POLAR_VORTEX",
                    source_line = 2131,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_HEADMASTER",
            source_line = 2135,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_MANA_VIPER",
                    source_line = 2137,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_DIMENSION_ANCHOR",
                    source_line = 2138,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_CLOSE",
                    source_line = 2139,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_ENERGY_BOLT",
                    source_line = 2140,
                    frequency = 15,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_NIKOLA",
            source_line = 2144,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 2146,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CHAIN_LIGHTNING",
                    source_line = 2147,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BLINK",
                    source_line = 2148,
                    frequency = 23,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_MAGGIE",
            source_line = 2152,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 2154,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_MESMERISE",
                    source_line = 2155,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_MARGERY",
            source_line = 2159,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 2161,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_FIREBALL",
                    source_line = 2162,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_FREDERICK",
            source_line = 2166,
            slots = {
                {
                    spell_id = "SPELL_FORCE_LANCE",
                    source_line = 2168,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 2169,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 2170,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_SPELLFORGED_SERVITOR",
                    source_line = 2171,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_PSYCHE",
            source_line = 2175,
            slots = {
                {
                    spell_id = "SPELL_CANTRIP",
                    source_line = 2177,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_POLYMORPH",
                    source_line = 2178,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_CHAIN_OF_CHAOS",
                    source_line = 2179,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
                {
                    spell_id = "SPELL_INVISIBILITY",
                    source_line = 2180,
                    frequency = 12,
                    flags = {
                        "MON_SPELL_WIZARD",
                    },
                },
            },
        },
        {
            id = "MST_GERYON",
            source_line = 2184,
            slots = {
                {
                    spell_id = "SPELL_SUMMON_HELL_BEAST",
                    source_line = 2186,
                    frequency = 65,
                    flags = {
                        "MON_SPELL_VOCAL",
                    },
                },
            },
        },
        {
            id = "MST_ASMODEUS",
            source_line = 2190,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_FIRE",
                    source_line = 2192,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_HURL_DAMNATION",
                    source_line = 2193,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FIRE_SUMMON",
                    source_line = 2194,
                    frequency = 22,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ANTAEUS",
            source_line = 2198,
            slots = {
                {
                    spell_id = "SPELL_LIGHTNING_BOLT",
                    source_line = 2200,
                    frequency = 24,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FLASH_FREEZE",
                    source_line = 2201,
                    frequency = 48,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_ERESHKIGAL",
            source_line = 2205,
            slots = {
                {
                    spell_id = "SPELL_BOLT_OF_COLD",
                    source_line = 2207,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 2208,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_TZITZIMITL",
                    source_line = 2209,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_PARALYSE",
                    source_line = 2210,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SILENCE",
                    source_line = 2211,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MAJOR_HEALING",
                    source_line = 2212,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                        "MON_SPELL_EMERGENCY",
                    },
                },
            },
        },
        {
            id = "MST_DISPATER",
            source_line = 2216,
            slots = {
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 2218,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
                    source_line = 2219,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_HURL_DAMNATION",
                    source_line = 2220,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_HELL_SENTINEL",
                    source_line = 2221,
                    frequency = 26,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_MNOLEG",
            source_line = 2225,
            slots = {
                {
                    spell_id = "SPELL_MALIGN_GATEWAY",
                    source_line = 2227,
                    frequency = 27,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_EYEBALLS",
                    source_line = 2228,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_HORRIBLE_THINGS",
                    source_line = 2229,
                    frequency = 27,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_CALL_OF_CHAOS",
                    source_line = 2230,
                    frequency = 27,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_DIG",
                    source_line = 2231,
                    frequency = 13,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_LOM_LOBON",
            source_line = 2235,
            slots = {
                {
                    spell_id = "SPELL_CONJURE_BALL_LIGHTNING",
                    source_line = 2237,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_GLACIATE",
                    source_line = 2238,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_POLAR_VORTEX",
                    source_line = 2239,
                    frequency = 60,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MAJOR_HEALING",
                    source_line = 2240,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_BLINK_RANGE",
                    source_line = 2241,
                    frequency = 30,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_CEREBOV",
            source_line = 2245,
            slots = {
                {
                    spell_id = "SPELL_IRON_SHOT",
                    source_line = 2247,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FIRE_STORM",
                    source_line = 2248,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_FIRE_SUMMON",
                    source_line = 2249,
                    frequency = 11,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_HASTE",
                    source_line = 2250,
                    frequency = 36,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_GLOORX_VLOQ",
            source_line = 2254,
            slots = {
                {
                    spell_id = "SPELL_POISON_ARROW",
                    source_line = 2256,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_MIASMA_BREATH",
                    source_line = 2257,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SYMBOL_OF_TORMENT",
                    source_line = 2258,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
                    source_line = 2259,
                    frequency = 20,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_SUMMON_EXECUTIONERS",
                    source_line = 2260,
                    frequency = 40,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
        {
            id = "MST_TEST_SPAWNER",
            source_line = 2265,
            slots = {
                {
                    spell_id = "SPELL_SHADOW_CREATURES",
                    source_line = 2267,
                    frequency = 100,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_PLANEREND",
                    source_line = 2268,
                    frequency = 67,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
                {
                    spell_id = "SPELL_PHANTOM_MIRROR",
                    source_line = 2269,
                    frequency = 33,
                    flags = {
                        "MON_SPELL_MAGICAL",
                    },
                },
            },
        },
    },
}
