-- nameless horror (MONS_NAMELESS) is a DCSS monster profile with 15 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 30 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_NAMELESS when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_NAMELESS",
    status = "defined",
    name = "nameless horror",
    glyph = 88,
    colour_id = "CYAN",
    flags = {
        "M_SEE_INVIS",
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
    },
    xp_modifier = 11,
    genus_id = "MONS_NAMELESS",
    species_id = "MONS_NAMELESS",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- nameless horror offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ANTIMAGIC",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 15,
    average_hp_10x = 600,
    ac = 8,
    ev = 2,
    spellbook_id = "MST_NAMELESS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For nameless horror, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_NAMELESS_HORROR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
