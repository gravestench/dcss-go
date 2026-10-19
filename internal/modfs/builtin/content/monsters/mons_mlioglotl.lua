-- Mlioglotl (MONS_MLIOGLOTL) is a DCSS monster profile with 15 hit dice and
-- speed 14.
-- Its first melee contact is AT_HIT for 20 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_MLIOGLOTL when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MLIOGLOTL",
    status = "defined",
    name = "Mlioglotl",
    glyph = 88,
    colour_id = "BROWN",
    flags = {
        "M_UNIQUE",
        "M_SPEAKS",
        "M_MALE",
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
    xp_modifier = 13,
    genus_id = "MONS_THRASHING_HORROR",
    species_id = "MONS_MLIOGLOTL",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 120,
    -- Mlioglotl offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 25,
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
    hd = 15,
    average_hp_10x = 1400,
    ac = 10,
    ev = 5,
    spellbook_id = "MST_MLIOGLOTL",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For Mlioglotl, energy costs combine with speed 14 to determine action
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_MLIOGLOTL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
