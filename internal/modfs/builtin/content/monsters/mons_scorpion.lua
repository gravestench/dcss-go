-- scorpion (MONS_SCORPION) is a DCSS monster profile with 4 hit dice and
-- speed 12.
-- Its first melee contact is AT_STING for 8 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SCORPION",
    status = "defined",
    name = "scorpion",
    glyph = 115,
    colour_id = "YELLOW",
    flags = {
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_SCORPION",
    species_id = "MONS_SCORPION",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- scorpion offers AT_STING as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_STING",
            flavour_id = "AF_POISON",
            damage = 8,
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
    hd = 4,
    average_hp_10x = 180,
    ac = 5,
    ev = 10,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For scorpion, energy costs combine with speed 12 to determine action
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_SCORPION",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SCORPION",
}

register.definition(categories.MONSTERS, definition)

return definition
