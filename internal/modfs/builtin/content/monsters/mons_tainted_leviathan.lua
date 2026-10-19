-- tainted leviathan (MONS_TAINTED_LEVIATHAN) is a DCSS monster profile with
-- 18 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 50 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_TAINTED_LEVIATHAN when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_TAINTED_LEVIATHAN",
    status = "defined",
    name = "tainted leviathan",
    glyph = 67,
    colour_id = "MAGENTA",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_MIASMA_RING",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_GIANT",
    species_id = "MONS_TAINTED_LEVIATHAN",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 120,
    -- tainted leviathan offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 50,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN",
            damage = 30,
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
    hd = 18,
    average_hp_10x = 1500,
    ac = 15,
    ev = 2,
    spellbook_id = "MST_TAINTED_LEVIATHAN",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For tainted leviathan, energy costs combine with speed 10 to determine
    -- action cadence, not an unconditional action each turn.
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_TAINTED_LEVIATHAN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_TAINTED_LEVIATHAN",
}

register.definition(categories.MONSTERS, definition)

return definition
