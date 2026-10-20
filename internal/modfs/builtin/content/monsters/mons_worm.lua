-- worm (MONS_WORM) is a DCSS monster profile with 4 hit dice and speed 6.
-- Its first melee contact is AT_BITE for 12 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_WORM",
    status = "defined",
    name = "worm",
    glyph = 119,
    colour_id = "LIGHTRED",
    flags = {
        "M_NO_SKELETON",
        "M_FAST_REGEN",
    },
    xp_modifier = 3,
    genus_id = "MONS_WORM",
    species_id = "MONS_WORM",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- worm offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 12,
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
    ac = 1,
    ev = 5,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 6,
    -- For worm, energy costs combine with speed 6 to determine action cadence, not
    -- an unconditional action each turn.
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
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_WORM",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WORM",
}

register.definition(categories.MONSTERS, definition)

return definition
