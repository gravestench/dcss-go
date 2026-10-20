-- hornet (MONS_HORNET) is a DCSS monster profile with 6 hit dice and speed
-- 15.
-- Its first melee contact is AT_STING for 18 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_HORNET",
    status = "defined",
    name = "hornet",
    glyph = 121,
    colour_id = "YELLOW",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_HORNET",
    species_id = "MONS_HORNET",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 30,
    -- hornet offers AT_STING as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_STING",
            flavour_id = "AF_POISON_PARALYSE",
            damage = 18,
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
    hd = 6,
    average_hp_10x = 330,
    ac = 6,
    ev = 14,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_BUZZ",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For hornet, energy costs combine with speed 15 to determine action cadence,
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
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_HORNET",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_HORNET",
}

register.definition(categories.MONSTERS, definition)

return definition
