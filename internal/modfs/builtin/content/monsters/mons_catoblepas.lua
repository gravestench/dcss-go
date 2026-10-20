-- catoblepas (MONS_CATOBLEPAS) is a DCSS monster profile with 14 hit dice and
-- speed 10.
-- Its first melee contact is AT_GORE for 36 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_CATOBLEPAS when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_CATOBLEPAS",
    status = "defined",
    name = "catoblepas",
    glyph = 89,
    colour_id = "MAGENTA",
    flags = {
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_PETRIFY",
            level = 1,
        },
    },
    xp_modifier = 8,
    genus_id = "MONS_YAK",
    species_id = "MONS_CATOBLEPAS",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- catoblepas offers AT_GORE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_GORE",
            flavour_id = "AF_PLAIN",
            damage = 36,
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
    hd = 14,
    average_hp_10x = 770,
    ac = 10,
    ev = 2,
    spellbook_id = spellbooks.MST_CATOBLEPAS,
    leaves_corpse = true,
    shout_id = "S_BELLOW",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For catoblepas, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_CATOBLEPAS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_CATOBLEPAS",
}

register.definition(categories.MONSTERS, definition)

return definition
