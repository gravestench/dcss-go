-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/descript/backgrounds.txt
-- SHA-256: 1263736a450652589bbeb6a4cd3d6e57a092059ff34040263af7a33333803570
-- Source: crawl-ref/source/dat/descript/species.txt
-- SHA-256: 7abe5f3033ae02981f8af6956add4db2f1e08ed69e688d5e213e0e906ee1fb5e
-- Source: crawl-ref/source/newgame.cc
-- SHA-256: 32e2055c3b71002a2a3610c322fa05b35f8a8b05f00411df46f1de70adf8ef69
-- Source: crawl-ref/source/skills.h
-- SHA-256: 6e43be85f9d80827d8a2a92229751d991069c8e8dd574b51a90edf078972f4c7
-- Source: crawl-ref/source/species-groups.h
-- SHA-256: 8cbc7cf3b24fbe904d9ce193d04ffcee7b27bfaa4fa44328210c7365b40b9a28
-- Source: crawl-ref/source/startup.cc
-- SHA-256: 82aef31832467f8797e0fd2d5f2818974fe1ddc2213c70445a062f2493282d2f
-- Source: crawl-ref/source/tag-version.h
-- SHA-256: 2f8ed7610ca03ba6014044f78ca9f9b9392208a37d3539119ef04bd853ab1dfa

local catalog = {
    schema_version = 1,
    source_version = "0.30-a0-23-ge60ba3568b0",
    startup_modes = {
        {
            id = "GAME_TYPE_NORMAL",
            label = "Dungeon Crawl",
            description = "Dungeon Crawl: The main game: full of monsters, items, gods and danger!",
        },
        {
            id = "GAME_TYPE_CUSTOM_SEED",
            label = "Choose Game Seed",
            description = "Play with a chosen custom dungeon seed.",
        },
        {
            id = "GAME_TYPE_TUTORIAL",
            label = "Tutorial for Dungeon Crawl",
            description = "Tutorial that covers the basics of Dungeon Crawl survival.",
        },
        {
            id = "GAME_TYPE_HINTS",
            label = "Hints Mode for Dungeon Crawl",
            description = "A mostly normal game that provides more advanced hints than the tutorial.",
        },
        {
            id = "GAME_TYPE_SPRINT",
            label = "Dungeon Sprint",
            description = "Hard, fixed single level game mode.",
        },
        {
            id = "GAME_TYPE_INSTRUCTIONS",
            label = "Instructions",
            description = "Help menu.",
        },
        {
            id = "GAME_TYPE_ARENA",
            label = "The Arena",
            description = "Pit computer controlled teams versus each other!",
        },
        {
            id = "GAME_TYPE_HIGH_SCORES",
            label = "High Scores",
            description = "View the high score list.",
        },
    },
    skill_columns = {
        {
            "SK_FIGHTING",
            "",
            "SK_MACES_FLAILS",
            "SK_AXES",
            "SK_POLEARMS",
            "SK_STAVES",
            "SK_UNARMED_COMBAT",
            "",
            "SK_SHORT_BLADES",
            "SK_LONG_BLADES",
            "SK_RANGED_WEAPONS",
            "",
            "SK_ARMOUR",
            "SK_DODGING",
            "SK_SHIELDS",
            "SK_STEALTH",
        },
        {
            "SK_SPELLCASTING",
            "SK_CONJURATIONS",
            "SK_HEXES",
            "SK_SUMMONINGS",
            "SK_NECROMANCY",
            "SK_TRANSLOCATIONS",
            "SK_TRANSMUTATIONS",
            "SK_FIRE_MAGIC",
            "SK_ICE_MAGIC",
            "SK_AIR_MAGIC",
            "SK_EARTH_MAGIC",
            "SK_POISON_MAGIC",
            "",
            "SK_INVOCATIONS",
            "SK_EVOCATIONS",
            "SK_THROWING",
        },
    },
}

return catalog
