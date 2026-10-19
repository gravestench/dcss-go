-- Ereshkigal (MONS_ERESHKIGAL) is a DCSS monster profile with 18 hit dice and
-- speed 14.
-- Its first melee contact is AT_HIT for 40 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_ERESHKIGAL when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ERESHKIGAL",
    status = "defined",
    name = "Ereshkigal",
    glyph = 38,
    colour_id = "WHITE",
    flags = {
        "M_UNIQUE",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_FEMALE",
        "M_TALL_TILE",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_HELL_LORD",
    species_id = "MONS_ERESHKIGAL",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    -- Ereshkigal offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN",
            damage = 40,
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
    hd = 18,
    average_hp_10x = 3510,
    ac = 10,
    ev = 30,
    spellbook_id = "MST_ERESHKIGAL",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For Ereshkigal, energy costs combine with speed 14 to determine action
    -- cadence, not an unconditional action each turn.
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ERESHKIGAL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
