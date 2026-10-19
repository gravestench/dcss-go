-- orb spider (MONS_ORB_SPIDER) is a DCSS monster profile with 10 hit dice and
-- speed 12.
-- Its first melee contact is AT_BITE for 15 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_ORB_SPIDER when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ORB_SPIDER",
    status = "defined",
    name = "orb spider",
    glyph = 115,
    colour_id = "MAGENTA",
    flags = {
        "M_NO_SKELETON",
        "M_MAINTAIN_RANGE",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_SPIDER",
    species_id = "MONS_ORB_SPIDER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- orb spider offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
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
    hd = 10,
    average_hp_10x = 420,
    ac = 3,
    ev = 10,
    spellbook_id = "MST_ORB_SPIDER",
    leaves_corpse = true,
    shout_id = "S_FAINT_SKITTER",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For orb spider, energy costs combine with speed 12 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 20,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_ORB_SPIDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ORB_SPIDER",
}

register.definition(categories.MONSTERS, definition)

return definition
