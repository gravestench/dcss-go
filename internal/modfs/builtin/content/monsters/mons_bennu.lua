-- bennu (MONS_BENNU) is a DCSS monster profile with 14 hit dice and speed 16.
-- Its first melee contact is AT_PECK for 27 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_BENNU",
    status = "defined",
    name = "bennu",
    glyph = 98,
    colour_id = "YELLOW",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_FAST_REGEN",
        "M_NO_POLY_TO",
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_NEG",
            level = 3,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_MIASMA",
            level = 1,
        },
    },
    xp_modifier = 6,
    genus_id = "MONS_BENNU",
    species_id = "MONS_BENNU",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
    -- bennu offers AT_PECK as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_PECK",
            flavour_id = "AF_HOLY",
            damage = 27,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 24,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 24,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 14,
    average_hp_10x = 770,
    ac = 6,
    ev = 16,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    shout_id = "S_SCREECH",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 16,
    -- For bennu, energy costs combine with speed 16 to determine action cadence,
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_BIRD",
    tile = {
        id = "TILEP_MONS_BENNU",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
