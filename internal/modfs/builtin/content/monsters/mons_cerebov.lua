-- Cerebov (MONS_CEREBOV) is a DCSS monster profile with 21 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 60 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_CEREBOV when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local monsters = require("ids.monsters")

local definition = {
    id = "MONS_CEREBOV",
    -- Cerebov's first guard is a brimstone fiend.
    -- Later guards favor sun demons and efreets over balrugs.
    band = {
        min = 5,
        max = 8,
        slots = {
            {
                monsters.MONS_BRIMSTONE_FIEND,
            },
            {
                {
                    id = monsters.MONS_BALRUG,
                    weight = 1,
                },
                {
                    id = monsters.MONS_SUN_DEMON,
                    weight = 3,
                },
                {
                    id = monsters.MONS_EFREET,
                    weight = 3,
                },
            },
        },
    },
    status = "defined",
    name = "Cerebov",
    glyph = 38,
    colour_id = "RED",
    flags = {
        "M_UNIQUE",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_TALL_TILE",
        "M_GENDER_NEUTRAL",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_DAMNATION",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_PANDEMONIUM_LORD",
    species_id = "MONS_CEREBOV",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    -- Cerebov offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 60,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 21,
    average_hp_10x = 6510,
    ac = 30,
    ev = 8,
    spellbook_id = spellbooks.MST_CEREBOV,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Cerebov, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_CEREBOV",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
