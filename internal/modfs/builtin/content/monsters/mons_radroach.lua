-- radroach (MONS_RADROACH) is a DCSS monster profile with 12 hit dice and
-- speed 10.
-- Its first melee contact is AT_BITE for 28 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_RADROACH when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_RADROACH",
    status = "defined",
    name = "radroach",
    glyph = 66,
    colour_id = "LIGHTRED",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 10,
    genus_id = "MONS_GIANT_COCKROACH",
    species_id = "MONS_RADROACH",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- radroach offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 28,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 16,
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
    average_hp_10x = 800,
    ac = 13,
    ev = 5,
    spellbook_id = spellbooks.MST_RADROACH,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For radroach, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_INSECT",
    tile = {
        id = "TILEP_MONS_RADROACH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_RADROACH",
}

register.definition(categories.MONSTERS, definition)

return definition
