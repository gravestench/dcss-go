-- kraken (MONS_KRAKEN) is a DCSS monster profile with 16 hit dice and speed
-- 14.
-- Its first melee contact is AT_BITE for 50 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_KRAKEN when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_KRAKEN",
    status = "defined",
    name = "kraken",
    glyph = 88,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_NO_SKELETON",
        "M_COLD_BLOOD",
    },
    xp_modifier = 6,
    genus_id = "MONS_KRAKEN",
    species_id = "MONS_KRAKEN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- kraken offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 50,
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
    average_hp_10x = 2080,
    ac = 20,
    spellbook_id = spellbooks.MST_KRAKEN,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_WATER",
    speed = 14,
    -- For kraken, energy costs combine with speed 14 to determine action cadence,
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_KRAKEN_HEAD",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_KRAKEN",
}

register.definition(categories.MONSTERS, definition)

return definition
