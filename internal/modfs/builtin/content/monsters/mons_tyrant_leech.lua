-- tyrant leech (MONS_TYRANT_LEECH) is a DCSS monster profile with 12 hit dice
-- and speed 8.
-- Its first melee contact is AT_BITE for 35 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_TYRANT_LEECH",
    status = "defined",
    name = "tyrant leech",
    glyph = 119,
    colour_id = "RED",
    flags = {
        "M_NO_SKELETON",
    },
    xp_modifier = 8,
    genus_id = "MONS_TYRANT_LEECH",
    species_id = "MONS_TYRANT_LEECH",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- tyrant leech offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_VAMPIRIC",
            damage = 35,
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
    hd = 12,
    average_hp_10x = 600,
    ac = 5,
    ev = 15,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 8,
    -- For tyrant leech, energy costs combine with speed 8 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_TYRANT_LEECH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_TYRANT_LEECH",
}

register.definition(categories.MONSTERS, definition)

return definition
