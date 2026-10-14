-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/descript/backgrounds.txt
-- Source: crawl-ref/source/dat/descript/species.txt
-- Source: crawl-ref/source/newgame.cc
-- Source: crawl-ref/source/skills.h
-- Source: crawl-ref/source/species-groups.h
-- Source: crawl-ref/source/startup.cc
-- Source: crawl-ref/source/tag-version.h

return {
    schema_version = 1,
    source_revision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f",
    source_version = "0.30-a0-23-ge60ba3568b0",
    tag_major_version = 34,
    source_files = {
        {
            path = "crawl-ref/source/dat/descript/backgrounds.txt",
            sha256 = "1263736a450652589bbeb6a4cd3d6e57a092059ff34040263af7a33333803570",
        },
        {
            path = "crawl-ref/source/dat/descript/species.txt",
            sha256 = "7abe5f3033ae02981f8af6956add4db2f1e08ed69e688d5e213e0e906ee1fb5e",
        },
        {
            path = "crawl-ref/source/newgame.cc",
            sha256 = "32e2055c3b71002a2a3610c322fa05b35f8a8b05f00411df46f1de70adf8ef69",
        },
        {
            path = "crawl-ref/source/skills.h",
            sha256 = "6e43be85f9d80827d8a2a92229751d991069c8e8dd574b51a90edf078972f4c7",
        },
        {
            path = "crawl-ref/source/species-groups.h",
            sha256 = "8cbc7cf3b24fbe904d9ce193d04ffcee7b27bfaa4fa44328210c7365b40b9a28",
        },
        {
            path = "crawl-ref/source/startup.cc",
            sha256 = "82aef31832467f8797e0fd2d5f2818974fe1ddc2213c70445a062f2493282d2f",
        },
        {
            path = "crawl-ref/source/tag-version.h",
            sha256 = "2f8ed7610ca03ba6014044f78ca9f9b9392208a37d3539119ef04bd853ab1dfa",
        },
    },
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
    species_groups = {
        {
            label = "Simple",
            ids = {
                "SP_HILL_ORC",
                "SP_MINOTAUR",
                "SP_MERFOLK",
                "SP_GARGOYLE",
                "SP_PALENTONGA",
                "SP_BASE_DRACONIAN",
                "SP_TROLL",
                "SP_GHOUL",
                "SP_GNOLL",
            },
        },
        {
            label = "Intermediate",
            ids = {
                "SP_HUMAN",
                "SP_KOBOLD",
                "SP_DEMONSPAWN",
                "SP_DJINNI",
                "SP_SPRIGGAN",
                "SP_TENGU",
                "SP_DEEP_ELF",
                "SP_OGRE",
                "SP_BARACHI",
            },
        },
        {
            label = "Advanced",
            ids = {
                "SP_VINE_STALKER",
                "SP_VAMPIRE",
                "SP_DEMIGOD",
                "SP_FORMICID",
                "SP_NAGA",
                "SP_OCTOPODE",
                "SP_FELID",
                "SP_METEORAN",
                "SP_MUMMY",
            },
        },
    },
    job_groups = {
        {
            label = "Warrior",
            ids = {
                "JOB_FIGHTER",
                "JOB_GLADIATOR",
                "JOB_MONK",
                "JOB_HUNTER",
                "JOB_BRIGAND",
            },
        },
        {
            label = "Adventurer",
            ids = {
                "JOB_ARTIFICER",
                "JOB_WANDERER",
                "JOB_DELVER",
            },
        },
        {
            label = "Zealot",
            ids = {
                "JOB_BERSERKER",
                "JOB_ABYSSAL_KNIGHT",
                "JOB_CINDER_ACOLYTE",
                "JOB_CHAOS_KNIGHT",
            },
        },
        {
            label = "Warrior-mage",
            ids = {
                "JOB_TRANSMUTER",
                "JOB_WARPER",
                "JOB_ARCANE_MARKSMAN",
                "JOB_ENCHANTER",
            },
        },
        {
            label = "Mage",
            ids = {
                "JOB_HEDGE_WIZARD",
                "JOB_CONJURER",
                "JOB_SUMMONER",
                "JOB_NECROMANCER",
                "JOB_FIRE_ELEMENTALIST",
                "JOB_ICE_ELEMENTALIST",
                "JOB_AIR_ELEMENTALIST",
                "JOB_EARTH_ELEMENTALIST",
                "JOB_VENOM_MAGE",
            },
        },
    },
    species_descriptions = {
        SP_BARACHI =
            "Barachim are slow-moving, amphibious humanoids who can hop long distances.\nTheir extended range of vi" ..
            "sion also allows them to be seen from further away.",
        SP_BASE_DRACONIAN =
            "Draconians are versatile hybrids. They mature when reaching level 7 and develop\na colour.",
        SP_DEEP_ELF = "Deep Elves have a strong affinity for all kinds of magic, but are very fragile.",
        SP_DEMIGOD =
            "Demigods refuse to worship any god, but make up for this with divine attributes\nand high reserves of " ..
            "health and magic.",
        SP_DEMONSPAWN = "Demonspawn are half human, half demon. They acquire strong demonic mutations as\nthey grow.",
        SP_DJINNI =
            "Djinn are ever-burning spirits. They learn spells innately, without books, and\ncast by drawing down t" ..
            "heir own fires.",
        SP_FELID =
            "Felids are many-lived cats possessing sentience. They are incapable of advanced\nitem manipulation or " ..
            "the use of armour or weapons.",
        SP_FORMICID =
            "Formicids are humanoid ants adept at digging. Their limbs are exceptionally\nstrong and they live in a" ..
            " state of permanent stasis.",
        SP_GARGOYLE =
            "Made of living stone, Gargoyles have a preternatural affinity for the earth.\nThey have low health, bu" ..
            "t their stone bodies are incredibly tough.",
        SP_GHOUL =
            "Ghouls are undead creatures, damned to rot eternally. They have sharp claws,\nand they heal from the d" ..
            "eath of the living.",
        SP_GNOLL =
            "Gnolls are canine-like humanoids. They are unable to specialise in any single\nskill, but instead grad" ..
            "ually become proficient in all skills at once.",
        SP_HILL_ORC =
            "Hill Orcs are skilled in close combat, and often dabble in offensive magic. Only\nthey may worship the" ..
            " Orc god Beogh.",
        SP_HUMAN = "Humans advance quickly in levels and have equal abilities in most skills.",
        SP_KOBOLD =
            "Kobolds are attuned to the shadows and can only see or be seen at a close range.\nThey are small and a" ..
            " little fragile, and are talented in most skills.",
        SP_MERFOLK =
            "Half fish, half human, Merfolk are citizens of both water and land. They are\nstrong combatants, and a" ..
            "dept at using magic to assist in battle.",
        SP_METEORAN =
            "A celestial being fallen to earth, brilliant and fearsome... but with little\ntime before darkness snu" ..
            "ffs them out.",
        SP_MINOTAUR =
            "Minotaurs are large muscular humans with bovine heads. They excel at all forms\nof close and ranged co" ..
            "mbat.",
        SP_MUMMY =
            "Compelled to walk by an ancient curse, Mummies are adept at Necromancy but\nlearn other skills very sl" ..
            "owly. They are unable to consume potions.",
        SP_NAGA =
            "Nagas are hybrids; human from the waist up, with a snake-like tail instead of\nlegs. They move very sl" ..
            "owly but are naturally resilient.",
        SP_OCTOPODE =
            "Octopodes are a species of amphibious cephalopods. They can wear eight rings,\nbut almost no armour fi" ..
            "ts them.",
        SP_OGRE =
            "Large, strong, and extremely robust, Ogres are competent at all forms of melee.\nNot merely brutes, th" ..
            "ey are also quite capable spellcasters.",
        SP_PALENTONGA = "Scaled mammals the size of horses, Palentongas are able to launch powerful\nrolling charges.",
        SP_SPRIGGAN =
            "Very small, very frail and very fast, Spriggans are highly competent stabbers\nand spellcasters.",
        SP_TENGU =
            "Tengu are bird-people who love to fight, both with weapons and spells. They are\nquite fragile, but th" ..
            "ey learn to fly swiftly later on.",
        SP_TROLL = "Trolls are monstrous creatures with powerful claws. They regenerate health\nrapidly.",
        SP_VAMPIRE =
            "Shifting between the states of life and undeath at will, Vampires are\naccomplished stabbers and caste" ..
            "rs.",
        SP_VINE_STALKER =
            "Frail symbionts, Vine Stalkers cannot regain health from potions. Their magical\nreserves absorb damag" ..
            "e, and they pack a magic-restoring bite.",
    },
    job_descriptions = {
        JOB_ABYSSAL_KNIGHT =
            "Abyssal Knights worship Lugonu, and are sent from the Abyss into the Dungeon to\nspread corruption and" ..
            " chaos.",
        JOB_AIR_ELEMENTALIST =
            "Air Elementalists have learned the Shock spell. Later on, their selection of\nAir Magic spells provide" ..
            "s them with the flexibility to survive.",
        JOB_ARCANE_MARKSMAN =
            "Arcane Marksmen carry a sling, and use magic to make their foes more\nvulnerable to attacks from afar.",
        JOB_ARTIFICER =
            "Artificers start with a few magic wands and a club. They'll need to find better\nweapons and armour be" ..
            "fore their wands run out.",
        JOB_BERSERKER =
            "Berserkers believe in Trog, the magic-hating god of frenzy. Not much can stop a\nraging berserker earl" ..
            "y on, apart from hubris.",
        JOB_BRIGAND = "Brigands carry poisoned darts and a small number of nasty curare darts.",
        JOB_CHAOS_KNIGHT =
            "Chaos Knights are playthings of the unpredictable Xom, and are subject to the\ngod's constantly changi" ..
            "ng moods.",
        JOB_CINDER_ACOLYTE =
            "Cinder Acolytes worship Ignis, drawing upon the flame of a dying god until\nthere is nothing left.",
        JOB_CONJURER = "Conjurers confront problems with damaging spells.",
        JOB_DELVER =
            "Delvers start their quest five levels below the surface. A set of powerful magic\nitems helps them sur" ..
            "vive the dangerous journey upward.",
        JOB_EARTH_ELEMENTALIST =
            "Earth Elementalists know the Sandblast spell, and can later learn more earthen\nspells suitable for su" ..
            "btle stabbing or brute-force blasting.",
        JOB_ENCHANTER =
            "Enchanters know a variety of Hexes that can incapacitate their foes, and are\nequipped with an enchant" ..
            "ed dagger and potions of invisibility.",
        JOB_FIGHTER =
            "Fighters are equipped with armour and shield, as well as a weapon of their\nchoice and a potion of mig" ..
            "ht.",
        JOB_FIRE_ELEMENTALIST =
            "Fire Elementalists have learned the Foxfire spell. Their other starting spells\nare likewise focused o" ..
            "n fiery destruction.",
        JOB_GLADIATOR =
            "Gladiators are ready for the arena with light armour, a weapon of their choice,\nand a few throwing we" ..
            "apons and nets.",
        JOB_HEDGE_WIZARD =
            "Hedge Wizards learn many minor magics, letting them backstab or escape their\nbewildered foes.",
        JOB_HUNTER = "Hunters carry a shortbow, light armour and a scroll of immolation.",
        JOB_ICE_ELEMENTALIST =
            "Ice Elementalists begin with the Freeze spell. The spells in their starting\nlibrary are quite versati" ..
            "le.",
        JOB_MONK =
            "Monks start with a simple weapon of their choice and a potion of divine ambrosia,\nand gain additional" ..
            " piety with the first god they worship.",
        JOB_NECROMANCER =
            "Necromancers are wizards specializing in the practice of death magic. They\nstart out with the Necroti" ..
            "se spell.",
        JOB_SUMMONER =
            "Summoners are able to cast Summon Small Mammal from the start, and begin with\nother Summonings spells" ..
            " in their library.",
        JOB_TRANSMUTER = "Transmuters learn spells to shift their form, making them powerful unarmed\nfighters.",
        JOB_VENOM_MAGE =
            "Venom Mages start with the Sting spell, and their poison magic is very\neffective against susceptible " ..
            "foes.",
        JOB_WANDERER = "Wanderers start with random equipment and skills.",
        JOB_WARPER =
            "Warpers start with a weapon of their choice, a scroll of blinking, boomerangs\nof dispersal, and some " ..
            "Translocation spells in their library.",
    },
}
