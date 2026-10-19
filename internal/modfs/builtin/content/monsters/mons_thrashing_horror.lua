-- thrashing horror (MONS_THRASHING_HORROR) is a DCSS monster profile with 9
-- hit dice and speed 25.
-- Its first melee contact is AT_TRAMPLE for 17 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_THRASHING_HORROR when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_THRASHING_HORROR",
    status = "defined",
    name = "thrashing horror",
    glyph = 88,
    colour_id = "YELLOW",
    flags = {
        "M_BATTY",
        "M_NO_POLY_TO",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_THRASHING_HORROR",
    species_id = "MONS_THRASHING_HORROR",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 60,
    -- thrashing horror offers AT_TRAMPLE as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 17,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 9,
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
    hd = 9,
    average_hp_10x = 495,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_THRASHING_HORROR",
    shout_id = "S_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 25,
    -- For thrashing horror, energy costs combine with speed 25 to determine action
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_THRASHING_HORROR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
