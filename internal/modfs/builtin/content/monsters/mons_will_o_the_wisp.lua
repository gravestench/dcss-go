-- will-o-the-wisp (MONS_WILL_O_THE_WISP) is a DCSS monster profile with 11
-- hit dice and speed 10.
-- Its first melee contact is AT_ENGULF for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_WILL_O_THE_WISP when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_WILL_O_THE_WISP",
    status = "defined",
    name = "will-o-the-wisp",
    glyph = 118,
    colour_id = "GREEN",
    flags = {
        "M_INSUBSTANTIAL",
        "M_FLIES",
        "M_SEE_INVIS",
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
    genus_id = "MONS_WILL_O_THE_WISP",
    species_id = "MONS_WILL_O_THE_WISP",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- will-o-the-wisp offers AT_ENGULF as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_ENGULF",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    hd = 11,
    average_hp_10x = 400,
    ac = 4,
    ev = 10,
    spellbook_id = "MST_WILL_O_THE_WISP",
    shout_id = "S_MOAN",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For will-o-the-wisp, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_WILL_O_THE_WISP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
