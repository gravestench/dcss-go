-- broodmother (MONS_BROODMOTHER) is a DCSS monster profile with 12 hit dice
-- and speed 12.
-- Its first melee contact is AT_BITE for 40 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_BROODMOTHER when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BROODMOTHER",
    status = "defined",
    name = "broodmother",
    glyph = 115,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 10,
    genus_id = "MONS_SPIDER",
    species_id = "MONS_BROODMOTHER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- broodmother offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_SPIDER",
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
    hd = 12,
    average_hp_10x = 1400,
    ac = 2,
    ev = 4,
    spellbook_id = "MST_BROODMOTHER",
    leaves_corpse = true,
    shout_id = "S_SKITTER",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For broodmother, energy costs combine with speed 12 to determine action
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
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_BROODMOTHER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BROODMOTHER",
}

register.definition(categories.MONSTERS, definition)

return definition
