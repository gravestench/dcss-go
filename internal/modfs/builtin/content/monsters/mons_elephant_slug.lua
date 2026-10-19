-- elephant slug (MONS_ELEPHANT_SLUG) is a DCSS monster profile with 20 hit
-- dice and speed 4.
-- Its first melee contact is AT_BITE for 40 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ELEPHANT_SLUG",
    status = "defined",
    name = "elephant slug",
    glyph = 119,
    colour_id = "WHITE",
    flags = {
        "M_NO_SKELETON",
        "M_CANT_SPAWN",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 2,
    genus_id = "MONS_ELEPHANT_SLUG",
    species_id = "MONS_ELEPHANT_SLUG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    -- elephant slug offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
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
    hd = 20,
    average_hp_10x = 1300,
    ac = 2,
    ev = 1,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 4,
    -- For elephant slug, energy costs combine with speed 4 to determine action
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
    shape_id = "MON_SHAPE_SNAIL",
    tile = {
        id = "TILEP_MONS_DART_SLUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ELEPHANT_SLUG",
}

register.definition(categories.MONSTERS, definition)

return definition
