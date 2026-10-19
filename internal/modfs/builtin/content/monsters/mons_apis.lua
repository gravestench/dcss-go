-- apis (MONS_APIS) is a DCSS monster profile with 16 hit dice and speed 10.
-- Its first melee contact is AT_GORE for 40 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_APIS",
    status = "defined",
    name = "apis",
    glyph = 89,
    colour_id = "WHITE",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 8,
    genus_id = "MONS_APIS",
    species_id = "MONS_APIS",
    holiness = {
        "MH_HOLY",
    },
    willpower = 100,
    -- apis offers AT_GORE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_GORE",
            flavour_id = "AF_HOLY",
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
    hd = 16,
    average_hp_10x = 1200,
    ac = 9,
    ev = 5,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For apis, energy costs combine with speed 10 to determine action cadence,
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_APIS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_APIS",
}

register.definition(categories.MONSTERS, definition)

return definition
