-- lich (MONS_LICH) is a DCSS monster profile with 20 hit dice and speed 10.
-- Its first melee contact is AT_TOUCH for 15 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_LICH when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_LICH",
    status = "defined",
    name = "lich",
    glyph = 76,
    colour_id = "LIGHTGREY",
    flags = {
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 18,
    genus_id = "MONS_LICH",
    species_id = "MONS_LICH",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 5000,
    -- lich offers AT_TOUCH as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_TOUCH",
            flavour_id = "AF_DRAIN",
            damage = 15,
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
    hd = 20,
    average_hp_10x = 800,
    ac = 10,
    ev = 10,
    spellbook_id = "MST_LICH",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For lich, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_LICH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
